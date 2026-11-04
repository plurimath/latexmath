# frozen_string_literal: true

require "set"

# Capture-shape normalization of an exported Parslet-style grammar
# (scripts/generate_grammar.rb). Pure stdlib; a pure function of the rules.
#
# Under Parslet's flattening rules one capture name can hold text, a hash or
# a list depending on which alternative matched. The normalizer rewrites the
# rule tree, only by ADDING captures (which never changes what the grammar
# accepts), so that every capture always holds one kind:
#
#   N1 text alternative   a text-only alternative of a node-bearing slot
#                         becomes `(x) as literal`
#   N2 empty alternative  `[x]` in a node-bearing slot becomes
#                         `x' / "" as empty` (legacy "" when absent)
#   N3 list in node slot  a list-producing part of a node-bearing slot
#                         becomes `(x) as list`
#   N4 list slot          a capture whose value is a repetition always
#                         yields a list: text elements get N1
#   N5 text sibling       in a sequence that legacy could fold to text, the
#                         text elements get N1 so their text survives
#   N6 forced rule        a rule that can return text or a node is
#                         normalized once, in place (all call sites)
#   N7 presence capture   a capture that always holds nil (it captures a
#                         lookahead) becomes `(x "" as present) as name`,
#                         so the model can tell it from an absent key
#
# A wrapper never changes the slice it holds. WRAPPERS describes how the
# test-only unwrap maps each wrapper back to the legacy value.
class ShapeNormalizer
  WRAPPERS = {
    "literal" => "text: the wrapped slice, as legacy would fold it",
    "empty" => "text: legacy produced the empty String \"\" (absent optional)",
    "list" => "list: legacy produced this list (an empty list was \"\")",
    "present" => "nil: legacy produced nil (a capture of a lookahead)",
  }.freeze

  Shape = Struct.new(:kinds, :hash_keys, :array_keys) do
    def self.empty = new(Set.new, Set.new, Set.new)
    def self.of(kind, hk = [], ak = []) = new(Set[kind], Set.new(hk), Set.new(ak))
    def |(o) = Shape.new(kinds | o.kinds, hash_keys | o.hash_keys, array_keys | o.array_keys)
    def solid = kinds - [:nil]
    def mixed? = solid.size > 1
  end
  STRING = Shape.of(:string).freeze
  NIL = Shape.of(:nil).freeze

  attr_reader :rules, :counts, :captures, :sites

  # +normalized+: the rules were already normalized (shape queries only).
  def initialize(rules, normalized: false)
    @rules = deep_copy(rules)
    @counts = Hash.new(0)
    @sites = Hash.new { |h, k| h[k] = Set.new }
    collisions = capture_names(@rules).select { |k| wrapper?(k) }
    raise ArgumentError, "the grammar already uses #{collisions.join(', ')}" unless normalized || collisions.empty?
  end

  # Rewrites until every capture holds one kind. Returns self.
  def run
    8.times do
      solve
      targets = @captures.select { |_, s| s.mixed? }.keys.to_set
      return self if targets.empty? && @captures.none? { |k, s| s.solid.empty? && !WRAPPERS.key?(k) }

      @forced_rules = Set.new
      @rules.each_key do |name|
        @current = name
        @rules[name] = visit(@rules[name], targets)
      end
    end
    solve
    # No capture may be multi-kind, and none may hold nil (the model could
    # not tell nil from an absent key).
    left = @captures.select { |k, s| s.mixed? || (s.kinds.include?(:nil) && !WRAPPERS.key?(k)) }
    raise "normalization did not converge: #{left.keys.join(', ')}" unless left.empty?

    self
  end

  # The value shape of every capture after #run (Parslet flattening).
  def solve
    @rule_shapes = Hash.new { |h, k| h[k] = Shape.empty }
    loop do
      @captures = Hash.new { |h, k| h[k] = Shape.empty }
      before = @rule_shapes.transform_values(&:to_a).hash
      @rules.each do |name, node|
        @rule_shapes[[name, false]] |= shape(node, false)
        @rule_shapes[[name, true]] |= shape(node, true)
      end
      break if @rule_shapes.transform_values(&:to_a).hash == before
    end
    @captures
  end

  def shape(node, named)
    if node.key?("alt") then node["alt"].map { |n| shape(n, named) }.reduce(:|)
    elsif node.key?("seq") then sequence(node["seq"].map { |n| shape(n, false) })
    elsif node.key?("as")
      @captures[node["as"]] |= shape(node["of"], true)
      Shape.of(:hash, [node["as"]])
    elsif node.key?("ref") then @rule_shapes[[node["ref"], named]]
    elsif node.key?("rep") then repetition(node, named)
    elsif node.key?("look") then NIL
    elsif node.key?("str") || node.key?("re") || node.key?("decimal_marker") then STRING
    else raise "unknown grammar node #{node.keys.inspect}"
    end
  end

  # Sequences where two parts can carry the same wrapper key (a merge
  # would drop one part's text). Empty after a sound #run.
  def collisions
    solve
    found = []
    walk = lambda do |n, rule|
      k = n.keys.first
      if k == "seq"
        seen = Hash.new(0)
        n["seq"].each { |c| shape(c, false).hash_keys.each { |key| seen[key] += 1 if wrapper?(key) } }
        found << "#{rule}: #{seen.select { |_, v| v > 1 }.keys.join(',')}" if seen.any? { |_, v| v > 1 }
      end
      case k
      when "seq", "alt" then n[k].each { |c| walk.call(c, rule) }
      when "rep", "look" then walk.call(n[k], rule)
      when "as" then walk.call(n["of"], rule)
      end
    end
    @rules.each { |r, b| walk.call(b, r) }
    found
  end

  # Wrapper capture names the rewritten rules use, with their kind.
  def wrapper_list
    used = capture_names(@rules).select { |k| wrapper?(k) }.sort
    used.to_h { |k| [k, { "list" => "list", "empty" => "empty", "present" => "nil" }.fetch(k, "text")] }
  end

  def wrapper?(key) = WRAPPERS.key?(key) || key.match?(/\Aliteral_\d+\z/)

  private

  def repetition(node, named)
    inner = shape(node["rep"], false)
    if node["tag"] == "maybe"
      absent = named ? NIL : STRING
      present = named ? inner : Shape.new(inner.kinds - [:nil], inner.hash_keys, inner.array_keys) |
                                (inner.kinds.include?(:nil) ? STRING : Shape.empty)
      return absent | present
    end
    out = Shape.empty
    out |= (named ? Shape.of(:array) : STRING) if node["min"].zero?
    if inner.kinds.intersect?(Set[:hash, :array])
      out |= Shape.new(Set[:array], Set.new, inner.hash_keys | inner.array_keys)
    end
    out |= STRING if inner.kinds.intersect?(Set[:string, :nil])
    out
  end

  def sequence(shapes)
    states = Set[[:none, Set.new, Set.new]]
    shapes.each do |s|
      states = states.each_with_object(Set.new) { |st, acc| s.kinds.each { |k| acc << fold(st, k, s) } }
    end
    states.reduce(Shape.empty) { |acc, (k, hk, ak)| acc | (k == :none ? STRING : Shape.new(Set[k], hk, ak)) }
  end

  def fold((kind, hk, ak), k, s)
    return [kind, hk, ak] if k == :nil
    return [k, k == :hash ? s.hash_keys : Set.new, k == :array ? s.array_keys : Set.new] if kind == :none

    case [kind, k]
    when %i[string string] then [:string, hk, ak]
    when %i[hash hash] then [:hash, hk | s.hash_keys, ak]
    when %i[array array] then [:array, hk, ak | s.array_keys]
    when %i[string hash] then [:hash, s.hash_keys, ak]
    when %i[hash string], %i[array string] then [kind, hk, ak]
    when %i[string array] then [:array, hk, s.array_keys]
    when %i[array hash] then [:array, hk, ak | s.hash_keys]
    when %i[hash array] then [:array, hk, s.array_keys | hk]
    end
  end

  # Walks a rule body; at every capture of a multi-kind name, normalizes
  # its inner node (N4 for repetitions, else to an always-hash value).
  def visit(node, targets)
    k = node.keys.first
    case k
    when "seq", "alt" then { k => node[k].map { |c| visit(c, targets) } }
    when "rep" then node.merge("rep" => visit(node["rep"], targets))
    when "look" then node.merge("look" => visit(node["look"], targets))
    when "as"
      inner = visit(node["of"], targets)
      if shape(node["of"], true).solid.empty? && !WRAPPERS.key?(node["as"])
        count("N7 presence capture")
        inner = { "seq" => [inner, { "as" => "present", "of" => { "str" => "" } }] }
      elsif targets.include?(node["as"])
        @sites[node["as"]] << @current
        inner = list_slot?(node["as"], inner) ? force_list(inner) : force_hash(inner, true)
      end
      { "as" => node["as"], "of" => inner }
    else node
    end
  end

  # A capture whose value is a repetition (N4) stays a list.
  def list_slot?(name, inner)
    inner.key?("rep") && inner["tag"] != "maybe" && @captures[name].solid.include?(:array)
  end

  def force_list(rep)
    count("N4 list slot")
    rep.merge("rep" => force_hash(rep["rep"], false))
  end

  # +node+ rewritten so that its value is always a hash (or nil).
  def force_hash(node, named)
    s = shape(node, named)
    return node if s.solid.subset?(Set[:hash])
    return wrap(node, "literal", "N1 text alternative") if s.solid.subset?(Set[:string])

    case node.keys.first
    when "alt" then { "alt" => node["alt"].map { |c| force_hash(c, named) } }
    when "ref" then force_ref(node, s, named)
    when "seq" then force_seq(node)
    when "rep"
      if node["tag"] == "maybe"
        raise "N2 at a named position in #{@current}" if named

        count("N2 empty alternative")
        { "alt" => [force_hash(node["rep"], false), { "as" => "empty", "of" => { "str" => "" } }] }
      elsif node["min"].zero?
        raise "list of min 0 in a node slot (#{@current}); not handled"
      else
        wrap(node.merge("rep" => force_hash(node["rep"], false)), "list", "N3 list in node slot")
      end
    else raise "cannot normalize #{node.keys.first} in #{@current}"
    end
  end

  def force_ref(node, s, named)
    return wrap(node, "list", "N3 list in node slot") if s.solid == Set[:array]

    name = node["ref"]
    unless @forced_rules.include?(name)
      @forced_rules << name
      count("N6 forced rule")
      saved = @current
      @current = name
      @rules[name] = force_hash(@rules[name], false)
      @current = saved
    end
    node
  end

  # N5: a text sibling is wrapped as literal, or literal_2, literal_3 ...
  # when another part of the same sequence can already carry that key, so
  # two text parts never merge into one key.
  def force_seq(node)
    elems = node["seq"]
    shapes = elems.map { |c| shape(c, false) }
    always_hash = shapes.any? { |e| e.kinds == Set[:hash] }
    out = elems.each_with_index.map do |c, i|
      e = shapes[i]
      if e.solid.include?(:array) || (e.mixed? && !always_hash)
        force_hash(c, false)
      elsif e.solid.subset?(Set[:string]) && !always_hash && texty?(c)
        :text
      else
        c
      end
    end
    # A part forced in this pass may carry literal once its rule is
    # rewritten; its recorded shape does not show that yet.
    taken = out.each_with_index.reject { |c, _| c == :text }
               .map { |c, i| shapes[i].mixed? ? shape(c, false).hash_keys | ["literal"] : shape(c, false).hash_keys }
               .reduce(Set.new, :|)
    out = out.each_with_index.map do |c, i|
      next c unless c == :text

      name = (1..).lazy.map { |n| n == 1 ? "literal" : "literal_#{n}" }.find { |w| !taken.include?(w) }
      taken << name
      wrap(elems[i], name, "N5 text sibling")
    end
    { "seq" => out }
  end


  # A text wrapper around an optional part would hold nil (or []) when the
  # part is absent, so `[x] as w` is written `x as w / "" as empty` and
  # `0*n(x) as w` is written `1*n(x) as w / "" as empty` (same language).
  def wrap(node, name, rule)
    count(rule)
    opt = optional(node)
    if name != "list" && opt
      count("N2 empty alternative")
      present = opt["tag"] == "maybe" ? opt["rep"] : opt.merge("min" => 1)
      return { "alt" => [{ "as" => name, "of" => present }, { "as" => "empty", "of" => { "str" => "" } }] }
    end
    { "as" => name, "of" => node }
  end

  # +node+, or the body of the rule chain it names (inlined at this site),
  # when that is an optional part: a maybe or a repetition of min 0.
  def optional(node, depth = 0)
    return node if node.key?("rep") && node["min"].zero?
    return optional(@rules.fetch(node["ref"]), depth + 1) if node.key?("ref") && depth < 8

    nil
  end

  def count(rule)
    @counts[rule] += 1
  end

  def texty?(node, seen = Set.new)
    case node.keys.first
    when "str" then !node["str"].empty?
    when "re", "decimal_marker" then true
    when "look", "as" then false
    when "ref"
      return false unless seen.add?(node["ref"])

      texty?(@rules[node["ref"]], seen)
    when "seq", "alt" then node[node.keys.first].any? { |c| texty?(c, seen) }
    when "rep" then texty?(node["rep"], seen)
    end
  end

  def capture_names(rules, out = Set.new)
    walk = lambda do |n|
      k = n.keys.first
      out << n["as"] if k == "as"
      case k
      when "seq", "alt" then n[k].each(&walk)
      when "rep", "look" then walk.call(n[k])
      when "as" then walk.call(n["of"])
      end
    end
    rules.each_value(&walk)
    out.to_a
  end

  def deep_copy(obj) = Marshal.load(Marshal.dump(obj))
end
