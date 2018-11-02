module Universa
  refine String do
    def camelize_lower
      first, *rest = split('_').delete_if(&:empty?)
      [first, *rest.map(&:capitalize)].join
    end
  end
end

