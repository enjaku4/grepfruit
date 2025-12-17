module Grepfruit
  module RactorCompat
    RUBY_4_OR_LATER = RUBY_VERSION >= "4.0"

    if RUBY_4_OR_LATER
      def self.create_worker(&block)
        port = Ractor::Port.new
        worker = Ractor.new(port, &block)
        [worker, port]
      end

      def self.send_work(worker, data)
        worker.send(data)
      end

      def self.receive_from_port(port)
        port.receive
      end

      def self.yield_result(port, data)
        port << data
      end

      def self.select_ready(workers_and_ports)
        workers = workers_and_ports.keys
        ports = workers_and_ports.values
        ready_port = Ractor.select(*ports)
        worker = workers_and_ports.key(ready_port)
        result = ready_port.receive
        [worker, result]
      end
    else
      def self.create_worker(&block)
        worker = Ractor.new(&block)
        [worker, nil]
      end

      def self.send_work(worker, data)
        worker.send(data)
      end

      def self.receive_from_port(_port)
        raise "Should not be called in Ruby 3"
      end

      def self.yield_result(_port, data)
        Ractor.yield(data)
      end

      def self.select_ready(workers_and_ports)
        workers = workers_and_ports.keys
        ready_worker, result = Ractor.select(*workers)
        [ready_worker, result]
      end
    end
  end
end