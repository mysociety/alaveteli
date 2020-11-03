require 'yaml'

##
# Parses refusal advice from data files and flattens into a single data
# structure.
#
class RefusalAdvice::Store
  def self.from_yaml(files)
    yamls = files.sort.inject([]) do |memo, file|
      yaml = YAML.load(File.read(file))
      memo << yaml if yaml
      memo
    end

    new(yamls)
  end

  def initialize(data)
    @data = data
  end

  def [](key)
    to_h[key.to_sym]
  end

  def to_h
    @to_h ||= data.inject({}) do |memo, set|
      memo.deep_merge!(set, &method(:merge_array_by_id))
    end.deep_symbolize_keys
  end

  def ==(other)
    data == other.data
  end

  protected

  attr_reader :data

  private

  def merge_array_by_id(_key, this_val, other_val)
    # check both values are arrays, if not return other value, just like
    # Hash#deep_merge
    return other_val unless this_val.is_a?(Array) || other_val.is_a?(Array)

    # combine array values
    values = [*this_val, *other_val]

    # filter items for hashes with id values
    hashes_with_ids = values.select { |val| val.is_a?(Hash) && val['id'] }
    other_values = values - hashes_with_ids

    # loop over all hashes with id values
    hashes_with_ids.inject(other_values) do |memo, val|
      # look for hash, already processed, with the same id
      existing_hash = memo.find { |h| h['id'] == val['id'] }

      # if there isn't an existing hash then we can add the hash and return
      next memo << val unless existing_hash

      # deep merge the hashes with matching ids and return
      existing_hash.deep_merge!(val, &method(:merge_array_by_id))
      memo
    end
  end
end
