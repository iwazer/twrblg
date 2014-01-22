module Kernel
  alias :put_string :puts
  def puts *args
    first = args.shift
    NSLog(first.try(:to_s) || "", *args)
  end
end
