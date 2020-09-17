module Latexmath
  module Packages
    class Amsmath
      def initialize(package)
        # NOTE: Use \@left,\@right here, to avoid the hidden grouping (see TeX.pool, \@hidden@bgroup)
        # NOTE: These defns have an  column spec [] (omit that for mathtools)
        package.macro('\matrix',    '\lx@ams@matrix{name=matrix,datameaning=matrix}')
        package.macro('\endmatrix', '\lx@end@ams@matrix')
        package.macro('\pmatrix', '\lx@ams@matrix{name=pmatrix,datameaning=matrix,left=\@left(,right=\@right)}')
        package.macro('\endpmatrix', '\lx@end@ams@matrix')
        package.macro('\bmatrix', '\lx@ams@matrix{name=bmatrix,datameaning=matrix,left=\@left[,right=\@right]}')
        package.macro('\endbmatrix', '\lx@end@ams@matrix')
        package.macro('\Bmatrix', '\lx@ams@matrix{name=Bmatrix,datameaning=matrix,left=\@left\{,right=\@right\}}')
        package.macro('\endBmatrix', '\lx@end@ams@matrix')
        package.macro('\vmatrix', '\lx@ams@matrix{name=vmatrix,delimitermeaning=determinant,datameaning=matrix,left=\@left|,right=\@right|}')
        package.macro('\endvmatrix', '\lx@end@ams@matrix')
        package.macro('\Vmatrix', '\lx@ams@matrix{name=Vmatrix,delimitermeaning=norm,datameaning=matrix,left=\@left\|,right=\@right\|}')
        package.macro('\endVmatrix', '\lx@end@ams@matrix')
        #package.macro('\smallmatrix',    '\lx@ams@matrix{name=smallmatrix,atameaning=matrix,left=\scriptsize}')
        package.macro('\smallmatrix',    '\lx@ams@matrix{name=smallmatrix,atameaning=matrix,style=\scriptsize}')
        package.macro('\endsmallmatrix', '\lx@end@ams@matrix')
      end
    end
  end
end
