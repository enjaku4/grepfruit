module Grepfruit
  module RactorCompat
    module_function

    def send_work(worker, data)
      worker.send(data)
    end

    if defined?(::Ractor::Port)
      def create_worker(&)
        port = Ractor::Port.new
        worker = Ractor.new(port, &)
        [worker, port]
      end

      def yield_result(port, data)
        port << data
      end

      def select_ready(workers_and_ports)
        ports = workers_and_ports.values
        ready_port, result = Ractor.select(*ports)
        worker = workers_and_ports.key(ready_port)
        [worker, result]
      end
    else
      def create_worker(&)
        worker = Ractor.new(&)
        [worker, nil]
      end

      def yield_result(_port, data)
        Ractor.yield(data)
      end

      def select_ready(workers_and_ports)
        workers = workers_and_ports.keys
        ready_worker, result = Ractor.select(*workers)
        [ready_worker, result]
      end
    end
  end
end
