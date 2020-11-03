class ValidatesBySchema::ValidationOption
  # column here must be an ActiveRecord column
  # i.e. MyARModel.columns.first
  attr_accessor :klass, :column

  def initialize(klass, column)
    @klass = klass
    @column = column
  end

  def define!
    if association
      if !ActiveRecord::Base.belongs_to_required_by_default && !column.null
        klass.validates association.name, presence: true
      end
    else
      options = to_hash
      klass.validates column.name, options if options.present?
    end
  end

  private

  def presence?
    presence && column.type != :boolean
  end

  def presence
    !column.null
  end

  def enum?
    klass.respond_to?(:defined_enums) && klass.defined_enums.has_key?(column.name)
  end

  def numericality?
    [:integer, :decimal, :float].include?(column.type) && !enum?
  end

  def numericality
    numericality = {}
    if column.type == :integer
      numericality[:only_integer] = true
      if integer_max
        numericality[:less_than] = integer_max
        numericality[:greater_than] = -integer_max
      end
    elsif column.type == :decimal && decimal_max
      numericality[:less_than_or_equal_to] = decimal_max
      numericality[:greater_than_or_equal_to] = -decimal_max
    end
    numericality[:allow_nil] = true
    numericality
  end

  def uniqueness?
    unique_indexes.one?
  end

  def uniqueness
    {
      allow_nil: column.null
    }
  end

  def unique_indexes
    klass
      .connection
      .indexes(klass.table_name)
      .select(&:unique)
      .select { |index| index.columns.include?(column.name) }
  end

  def array?
    column.respond_to?(:array) && column.array
  end

  def length?
    [:string, :text].include?(column.type) && column.limit && !array?
  end

  def length
    { maximum: column.limit, allow_nil: true }
  end

  def inclusion?
    column.type == :boolean
  end

  def inclusion
    { in: [true, false], allow_nil: column.null }
  end

  def integer_max
    (2**(8 * column.limit)) / 2 if column.limit
  end

  def decimal_max
    10.0**(column.precision - column.scale) - 10.0**(-column.scale) if column.precision && column.scale
  end

  def association
    @association ||= klass.reflect_on_all_associations(:belongs_to).find do |a|
      a.foreign_key.to_s == column.name
    end
  end

  def to_hash
    [:presence, :numericality, :length, :inclusion, :uniqueness].inject({}) do |h, k|
      send(:"#{k}?") ? h.merge(k => send(k)) : h
    end
  end

  def to_s
    to_hash.inspect
  end

end
