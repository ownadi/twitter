require 'http/parser'
require 'openssl'
require 'resolv'
require 'socksify'

module Twitter
  module Streaming
    class Connection
      def initialize(opts = {})
        @tcp_socket_class = opts.fetch(:tcp_socket_class) { TCPSocket }
        @ssl_socket_class = opts.fetch(:ssl_socket_class) { OpenSSL::SSL::SSLSocket }
        @proxy            = opts.fetch(:proxy)            { nil }
      end
      attr_reader :tcp_socket_class, :ssl_socket_class

      def stream(request, response)
        if @proxy
          Socksify::proxy(@proxy[:ip], @proxy[:port]) do
            do_stream(request, response)
          end
        else
          do_stream(request, response)
        end
      end

      private

      def do_stream(request, response)
        client_context = OpenSSL::SSL::SSLContext.new
        client         = @tcp_socket_class.new(Resolv.getaddress(request.socket_host), request.socket_port)
        ssl_client     = @ssl_socket_class.new(client, client_context)

        ssl_client.connect
        request.stream(ssl_client)
        while body = ssl_client.readpartial(1024) # rubocop:disable AssignmentInCondition
          response << body
        end
      end
    end
  end
end
