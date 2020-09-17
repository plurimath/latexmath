module Latexmath
  module Packages
    module Latex
      #======================================================================
      # C.1.2 Environments
      #======================================================================

      # In LaTeX, \newenvironment{env} defines \env and \endenv.
      # \begin{env} & \end{env} open/close a group, and invoke these.
      # In fact, the \env & \endenv don't have to have been created by
      # \newenvironment; And in fact \endenv doesn't even have to be defined!
      # [it is created by \csname, and equiv to \relax if no previous defn]

      # We need to respect these usages here, but we also want to be able
      # to define environment constructors that `capture' the body so that
      # it can be processed specially, if needed.  These are the magic
      # '\begin{env}', '\end{env}' control sequences created by DefEnvironment.


      Macro.new('\begin{}')

      # DefMacro('\begin{}', sub {
      #     my ($gullet, $env) = @_;
      #     my $name   = $env && ToString(Expand($env));
      #     my $before = LookupValue('@environment@' . $name . '@beforebegin');
      #     my $after  = LookupValue('@environment@' . $name . '@atbegin');
      #     if (IsDefined("\\begin{$name}")) {
      #       (($before ? @$before : ()),
      #         T_CS("\\begin{$name}")); }    # Magic cs!
      #     else {
      #       my $token = T_CS("\\$name");
      #       if (!IsDefined($token)) {
      #         my $undef = '{' . $name . '}';
      #         $STATE->noteStatus(undefined => $undef);
      #         Error('undefined', $undef, $gullet, "The environment " . $undef . " is not defined.");
      #         $STATE->installDefinition(LaTeXML::Core::Definition::Constructor->new($token, undef,
      #             sub { $_[0]->makeError('undefined', $undef); })); }
      #       (($before ? @$before : ()),
      #         T_CS('\begingroup'),
      #         ($after ? @$after : ()),
      #         Invocation(T_CS('\lx@setcurrenvir'), $env),
      #         $token,); } });

      # DefMacro('\end{}', sub {
      #     my ($gullet, $env) = @_;
      #     my $name   = $env && ToString(Expand($env));
      #     my $before = LookupValue('@environment@' . $name . '@atend');
      #     my $after  = LookupValue('@environment@' . $name . '@afterend');
      #     my $t;

      #     if (IsDefined($t = T_CS("\\end{$name}"))) {
      #       ($t,
      #         ($after ? @$after : ())); }    # Magic CS!
      #     else {
      #       $t = T_CS("\\end$name");
      #       (($before ? @$before : ()),
      #         (IsDefined($t) ? $t : ()),
      #         T_CS('\endgroup'),
      #         ($after ? @$after : ())); } });
    end
  end
end
