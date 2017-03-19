module CForum
  class Exception < RuntimeError
    def initialize(status = 500, msg = '')
      @status = status
      super(msg)
    end
  end

  class NotFoundException < CForum::Exception
    def initialize(status = 404, msg = 'Ressource could not be found')
      super(status, msg)
    end
  end

  class ForbiddenException < CForum::Exception
    def initialize(status = 403, msg = 'Forbidden')
      super(status, msg)
    end
  end
end
