module CForum
  class Exception < ::Exception
    def initialize(status = 500, msg = "")
      @status = status
      super(msg)
    end
  end

  class NotFoundException < Exception
    def initialize(status = 404, msg = "Ressource could not be found")
      super(status, msg)
    end
  end
end