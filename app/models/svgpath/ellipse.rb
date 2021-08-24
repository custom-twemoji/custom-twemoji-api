# frozen_string_literal: true

# Conversion of svgpath
# https://github.com/fontello/svgpath/blob/2.3.1/lib/ellipse.js

# The precision used to consider an ellipse as a circle
epsilon = 0.0000000001

# To convert degree in radians
torad = Math::PI / 180

# Class constructor :
#  an ellipse centred at 0 with radii rx,ry and x - axis - angle ax.
class Ellipse
  def initialize(rx, ry, ax)
    return Ellipse.new(rx, ry, ax) unless self.instance_of? Ellipse
    @rx = rx
    @ry = ry
    @ax = ax
  end

  # Apply a linear transform m to the ellipse
  # m is an array representing a matrix :
  #    -         -
  #   | m[0] m[2] |
  #   | m[1] m[3] |
  #    -         -
  def transform(m)
    # We consider the current ellipse as image of the unit circle
    # by first scale(rx,ry) and then rotate(ax) ...
    # So we apply ma =  m x rotate(ax) x scale(rx,ry) to the unit circle.
    c = Math.cos(@ax * torad), s = Math.sin(@ax * torad)
    ma = [
      @rx * (m[0]*c + m[2]*s),
      @rx * (m[1]*c + m[3]*s),
      @ry * (-m[0]*s + m[2]*c),
      @ry * (-m[1]*s + m[3]*c)
    ]

    # ma * transpose(ma) = [ j l ]
    #                      [ l k ]
    # l is calculated later (if the image is not a circle)
    j = ma[0]*ma[0] + ma[2]*ma[2]
    k = ma[1]*ma[1] + ma[3]*ma[3]

    # the discriminant of the characteristic polynomial of ma * transpose(ma)
    d = ((ma[0]-ma[3])*(ma[0]-ma[3]) + (ma[2]+ma[1])*(ma[2]+ma[1])) *
        ((ma[0]+ma[3])*(ma[0]+ma[3]) + (ma[2]-ma[1])*(ma[2]-ma[1]))

    # the "mean eigenvalue"
    jk = (j + k) / 2

    # check if the image is (almost) a circle
    if (d < epsilon * jk)
      # if it is
      @rx = @ry = Math.sqrt(jk)
      @ax = 0
      self
    end

    # if it is not a circle
    l = ma[0]*ma[1] + ma[2]*ma[3]

    d = Math.sqrt(d)

    # {l1,l2} = the two eigen values of ma * transpose(ma)
    l1 = jk + d/2
    l2 = jk - d/2
    # the x - axis - rotation angle is the argument of the l1 - eigenvector
    @ax = (l.abs() < epsilon && (l1 - k).abs() < epsilon) ?
      90
    :
      Math.atan(l.abs() > (l1 - k).abs() ?
        (l1 - j) / l
      :
        l / (l1 - k)
      ) * 180 / Math::PI

    # if ax > 0 => rx = sqrt(l1), ry = sqrt(l2), else exchange axes and ax += 90
    if @ax >= 0
      # if ax in [0,90]
      @rx = Math.sqrt(l1)
      @ry = Math.sqrt(l2)
    else
      # if ax in ]-90,0[ => exchange axes
      @ax += 90
      @rx = Math.sqrt(l2)
      @ry = Math.sqrt(l1)
    end

    self
  end

  # Check if the ellipse is (almost) degenerate, i.e. rx = 0 or ry = 0
  def isDegenerate()
    (@rx < epsilon * @ry || @ry < epsilon * @rx)
  end
end
