module Universa

  module Checks
    protected

    def ensure_type obj, type, name
      obj.is_a?(type) or raise ArgumentError, "#{name} must be a #{type}, but is a #{obj.type}"
    end

    def ensure_nullable_type obj, type, name
      obj == nil || ensure_type(obj, type, name)
    end
  end

  # Adapter for  java.time.Duration class used in some Universa calls
  class Duration < RemoteAdapter
    remote_class "java.time.Duration"

    static_method :of_seconds
    static_method :of_minutes
    static_method :of_hours
    static_method :of_days

  end

  # Secure loan helper class builds and runs secure loan smart contracts
  class SecureLoanHelper < RemoteAdapter
    remote_class "com.icodici.universa.contract.helpers.SecureLoanHelper"

    static_method :initSecureLoan

    extend Checks

    # initSecureLoan with named arguments and type checks.
    # 
    # @param [KeyAddress] lender_address
    # @param [KeyAddress] borrower_address
    # @param [Contract] loan_contract
    # @param [Duration] duration
    # @param [Map] data
    # @param [Contract] collateral
    # @param [Boolean] mintable
    # @param [BigDecimal] repayment_amount
    # @param [String] repayment_currency
    # @param [KeyAddress] repayment_origin
    #
    # @return [Array()Contrtact)] two elements contracts array: loan contract, modified
    def self.create(lender_address:, borrower_address:, loan_contract:, duration:, data: {}, collateral:,
        mintable:, repayment_amount:, repayment_currency: nil, repayment_origin: nil, repayment_issuer: nil)

      ensure_type lender_address, KeyAddress, "lender_address"
      ensure_type borrower_address, KeyAddress, "lender_address"
      ensure_type loan_contract, Contract, "loan_contract"
      ensure_type duration, Duration, "duration"
      ensure_type collateral, Contract, "collateral"
      ensure_type repayment_amount, BigDecimal, "repayment_amount"
      ensure_nullable_type repayment_currency, String, "repayment_currency"
      ensure_nullable_type repayment_origin, HashId, "repayment_currency"
      ensure_nullable_type repayment_issuer, KeyAddress, "repayment_issuer"

      initSecureLoan(Binder.of(data), lender_address, borrower_address, loan_contract, duration, collateral, repayment_amount,
                     mintable, repayment_origin, repayment_issuer, repayment_currency)

    end
  end
end
