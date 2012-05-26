module Chapman
  module Exceptions
    class NoJobsDefined < RuntimeError; end
    class NoSuchJob < RuntimeError; end
    class JobTimeout < RuntimeError; end
    class BadURL < RuntimeError; end    
  end
end