module MyLibraryOnLinuxError
  class Error < StandardError
    def initialize(msg = nil)
      super(msg)
    end

    class ResquestError < Error
    end
  end
end
