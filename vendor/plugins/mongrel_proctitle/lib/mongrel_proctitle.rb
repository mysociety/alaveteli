module Mongrel
  
  # Mongrel process title modification.  
  class Proctitler
      
    # Initializes titler.    
    def initialize(port, prefix)
      @prefix = prefix
      @port = port
      @mutex = Mutex.new
      @titles = []
      @queue_length = 0
      @request_count = 0
    end
    
    # Returns port used in title.
    def port
      @port
    end
    
    # Return port used in title.
    def port=(new_port)
      @port = new_port
    end
    
    def request(&block)
      titles, mutex = @titles, @mutex
      mutex.synchronize do
        @queue_length += 1
        titles.push(self.title)
      end
      begin
        yield
      ensure
        mutex.synchronize do
          @queue_length -= 1
          @request_count += 1
          self.title = titles.pop || "xxx"
        end
      end
    end
    
    # Reports process as being idle.
    def set_idle
      self.title = "idle"
    end
    
    # Reports process as handling a socket.
    def set_processing(socket)
      self.title = "handling #{socket.peeraddr.last}"
    end

    # Reports process as handling a socket.
    def set_handling(request)
      params = request.params
      address = params['REMOTE_ADDR']
      method = params['REQUEST_METHOD']
      path = params['REQUEST_PATH']
      path = "#{path[0, 60]}..." if path.length > 60
      self.title = "handling #{address}: #{method} #{path}"
    end
    
    # Returns current title
    def title
      @title
    end
    
    # Sets process title.
    def title=(title)
      @title = title
      update_process_title
    end
    
    # Updates the process title.
    def update_process_title
      title = "#{@prefix} ["
      title << (@port ? "#{@port}" : "?")
      title << "/#{@queue_length}"
      title << "/#{@request_count}"
      title << "]: #{@title}"
      $0 = title
    end

  end
  
  # Handler which sets process title before request.
  class ProctitleHandler < HttpHandler
    def initialize(titler)
      @titler = titler
    end

    def process(request, response)
      @titler.set_handling(request)
    end    
  end

  class HttpServer

    def run_with_proctitle(*args)
      @titler = Proctitler.new(self.port, File.basename($0))
      @titler.set_idle
      run_without_proctitle
    end
    alias_method :run_without_proctitle, :run
    alias_method :run, :run_with_proctitle

    def process_client_with_proctitle(client)
      unless @handler
        @handler = ProctitleHandler.new(@titler)
        register("/", @handler, true)
      end
      @titler.request do
        @titler.set_processing(client)
        return process_client_without_proctitle(client)
      end
    end
    alias_method :process_client_without_proctitle, :process_client
    alias_method :process_client, :process_client_with_proctitle

  end
  
end
