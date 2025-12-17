module Grepfruit
  module RactorCompat
    RUBY_4_OR_LATER = RUBY_VERSION >= "4.0"

    if RUBY_4_OR_LATER
      def self.create_worker(&)
        port = Ractor::Port.new
        worker = Ractor.new(port, &)
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
        workers_and_ports.keys
        ports = workers_and_ports.values
        ready_port, result = Ractor.select(*ports)
        worker = workers_and_ports.key(ready_port)
        [worker, result]
      end
    else
      def self.create_worker(&)
        worker = Ractor.new(&)
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
