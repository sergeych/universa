require 'forwardable'
require_relative './entry'

# Filesystem-based storage. See {FileStore}. Under reconsidering, please do not use it yet.
module Universa::FSStore

  # Simple file-based store that could be efficiently user with per-file cloud storages like Dropbox,
  # Google Disk, NextCloud and like.
  #
  # Notes to developers:
  #
  # - attributes are eager loaded: should always be contructed from contract or from file
  # - contract is lazy loaded
  class FileStore < Universa::ChainStore

    # [String] The file store root path
    attr :root

    # Construct store in the path supplied. If the path is not empty, it will be scanned for stored contracts.
    # @param [String] root_path of the store, must exist.
    def initialize(root_path)
      @root = root_path
      @root = @root[0...-1] while (@root[-1] == '/')
      init_cache
    end

    # (see ChainStore#store_contract)
    def store_contract contract
      entry = FSStore::Entry.new(self)
      entry = entry.init_with_contract(contract)
      add_to_cache entry
    end

    # (see ChainStore#find_by_id)
    def find_by_id hash_id
      @cache[hash_id]
    end

    # (see ChainStore#count)
    def count
      @cache.size
    end

    protected

    # scan the root folder for attribute files and store them in the cache
    def init_cache
      @cache = {}
      Dir[@root + "/*.unicon.yaml"].each {|name|
        add_to_cache Entry.new(self).load_from_yaml_file(name)
      }
    end

    # add single entry to the cache
    # @param [Entry] entry to add. Could have contract not yet loaded but should be configured with attributes.
    def add_to_cache(entry)
      raise ArgumentError, "entry can't be nil" unless entry
      @cache[entry.hash_id] = entry
    end

  end

end