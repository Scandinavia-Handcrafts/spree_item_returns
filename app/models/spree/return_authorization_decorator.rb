Spree::ReturnAuthorization.class_eval do
  attr_accessor :user_initiated

  validates :stock_location, presence: true, unless: :user_initiated?
  validates :return_items, presence: true, if: :user_initiated?
  after_commit :notify_admin, on: :create, if: :user_initiated?
  after_commit :notify_user, on: :create, if: :user_initiated?

  def self.skip_stock_location_validation
    ## FIXME_NISH: Let's discuss this how we can refactor this one.
    stock_location_validations = _validators[:stock_location]
    if stock_location_validations.present?
      stock_location_validations.reject! { |validation| validation.is_a? ActiveRecord::Validations::PresenceValidator }
    end

    _validate_callbacks.each do |callback|
      callback.raw_filter.attributes.delete :stock_location if callback.raw_filter.is_a?(ActiveModel::Validations::PresenceValidator)
    end
  end

  def user_initiated?
    !!user_initiated
  end

  private
    def notify_admin
      Spree::ReturnAuthorizationMailer.notify_return_initialization_to_admin(number).deliver_later
    end

    def notify_user
      Spree::ReturnAuthorizationMailer.notify_return_initialization_to_user(number).deliver_later
    end

end

Spree::ReturnAuthorization.skip_stock_location_validation
