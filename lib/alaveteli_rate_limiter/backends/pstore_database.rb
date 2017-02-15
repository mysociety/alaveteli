# -*- encoding : utf-8 -*-
require 'pathname'
require 'pstore'

module AlaveteliRateLimiter
  module Backends
    class PStoreDatabase
      attr_reader :pstore

      def initialize(opts = {})
        @pstore = PStore.new(Pathname.new(opts.fetch(:path)))
      end

      def get(key)
        pstore.transaction do
          pstore.fetch(key, [])
        end
      end

      def set(key, records)
        pstore.transaction do
          pstore[key] = records
        end
      end

      def record(key)
        pstore.transaction do
          records = pstore.fetch(key, [])
          records << Time.zone.now.to_datetime
          pstore[key] = records
        end
      end

      def ==(other)
        pstore.path == other.pstore.path
      end

      def destroy
        File.delete(pstore.path) if File.exist?(pstore.path)
      end
    end
  end
end
