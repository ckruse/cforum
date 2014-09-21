# -*- coding: utf-8 -*-

class NotificationCenter
  def initialize
    @hooks = {}
  end

  def notify(hook, *args)
    retvals = []
    args.unshift hook

    if @hooks[hook]
      @hooks[hook].each do |h|
        if h.is_a?(Proc)
          retvals << h.call(*args)
        else
          retvals << h.notify(*args)
        end
      end
    end

    retvals
  end

  def register_hook(name, obj = nil, front = false, &block)
    @hooks[name] = [] unless @hooks[name]
    if front
      @hooks[name] = [obj || block] + @hooks[name]
    else
      @hooks[name] << (obj || block)
    end
  end
end

# eof
