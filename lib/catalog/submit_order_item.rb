module Catalog
  class SubmitOrderItem
    include SourceMixin

    attr_reader :order_item

    def initialize(order_item)
      @order_item = order_item
    end

    def process
      validate_before_submit
      TopologicalInventory::Service.call do |api_instance|
        result = api_instance.order_service_offering(order_item.portfolio_item.service_offering_ref, parameters)
        order_item.mark_ordered("Ordered", :topology_task_ref => result.task_id)
        Rails.logger.info("OrderItem #{order_item.id} ordered with topology task ref #{result.task_id}")
      end
      self
    end

    private

    def validate_before_submit
      raise ::Catalog::NotAuthorized unless valid_source?(order_item.portfolio_item.service_offering_source_ref)

      return unless Catalog::SurveyCompare.any_changed?(order_item.portfolio_item.service_plans)

      order_item.mark_failed("Order Item Failed: Base survey does not match Topology")
      raise Catalog::InvalidSurvey, "Base survey does not match Topology"
    end

    def parameters
      TopologicalInventoryApiClient::OrderParametersServiceOffering.new.tap do |obj|
        obj.service_parameters = sanitized_parameters
        obj.provider_control_parameters = order_item.provider_control_parameters
        obj.service_plan_id = order_item.service_plan_ref
      end
    end

    def sanitized_parameters
      Catalog::OrderItemSanitizedParameters.new(
        :order_item         => order_item,
        :do_not_mask_values => true
      ).process.sanitized_parameters
    end
  end
end
