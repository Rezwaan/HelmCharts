class Integrations::Sdm::Serializers::DomeToSdm::OrderSerializer
  def initialize(
    order_dto:,
    customer_id:,
    concept_id:,
    integration_store:,
    integration_catalog:,
    address_id:,
    source:,
    payment_config:
  )
    @order_dto = order_dto
    @customer_id = customer_id
    @concept_id = concept_id
    @integration_store = integration_store
    @integration_catalog = integration_catalog
    @address_id = address_id
    @source = source
    @payment_config = payment_config
  end

  def serialize
    # Line items need to be cerialized to what SDM calls a CEntry
    line_items = @order_dto.line_items

    c_entries =
      line_items.map { |line_item| line_item_to_c_entries(line_item) }.flatten

    total_price = line_items.sum(0.0) { |line_item| line_item["total_price"] }

    {
      # All properties outside the order object should be lowerCamelCase
      "tns:conceptID" => @concept_id,

      # All properties inside the order object should be UpperCamelCase
      "tns:order" => {
        "sdm:AddressID" => @address_id,
        "sdm:BackupStoreID" => @integration_store.external_reference,
        "sdm:ConceptID" => @concept_id,
        "sdm:CustomerID" => @customer_id,

        # Passing the entries as a hash instead of an array is necessary due to
        # how Savon serializes to XML.
        # See: https://stackoverflow.com/questions/20982594/passing-array-elements-for-savon-2-soap
        "sdm:Entries" => {"sdm:CEntry" => c_entries},

        "sdm:OrderMode" => 2, # Takeaway
        "sdm:OriginalStoreID" => @integration_store.external_reference,
        "sdm:PaymentMethod" => "Credit",
        "sdm:Payments" => {
          "sdm:CC_ORDER_PAYMENT" => {
            # TODO: To avoid floating point approximation issues, perhaps
            # use either a string or BigDecimal?
            "sdm:PAY_AMOUNT" => @order_dto.amount.to_f,
            "sdm:PAY_STATUS" => "1",
            "sdm:PAY_STORE_TENDERID" => payment_tender_id,
            "sdm:PAY_SUB_TYPE" => payment_sub_type,
            "sdm:PAY_TYPE" => "2",
          },
        },
        "sdm:ServiceCharge" => 0,
        "sdm:Source" => @source,
        "sdm:Status" => "0", # Initial
        "sdm:StoreID" => @integration_store.external_reference,
        "sdm:SubTotal" => total_price,
        "sdm:Total" => total_price,
        "sdm:ValidateStore" => 1,
      },

      "tns:autoApprove" => true,
      "tns:useBackupStoreIfAvailable" => true,
      "tns:orderNotes1" => "Swyft Order ID: #{@order_dto.backend_id}",
      "tns:orderNotes2" => payment_note,
      # The casing is weird on this one but that's how they made it in SDM
      "tns:creditCardPaymentbool" => false,
      "tns:isSuspended" => false,
      "tns:menuTemplateID" => @integration_catalog.external_data["menu_template_id"],
    }
  end

  private

  def line_item_to_c_entries(line_item)
    return [] if line_item.nil?

    modifiers_c_entries =
      get_modifiers(line_item: line_item).map { |m|
        modifiers_to_c_entries(m)
      }.flatten

    c_entries = []
    quantity = line_item.quantity.to_i

    # SDM doesn't have the concept of an item with quantity, we need to repeat
    # the item as many times as the quantity we have
    quantity.times do
      c_entries <<
        {
          # It might look confusing that a CEntry has CEntries, but that is how
          # SDM did it, the nested CEntries are actually modifiers
          "sdm:Entries" => {"sdm:CEntry" => modifiers_c_entries},
          # TODO: support multiple items per bundle. For now we are using only first item_bundle
          "sdm:ItemID" => line_item.item_detail_reference.dig(:item_bundles, 0, :item, :item_id),
          "sdm:Price" => line_item.total_price.to_f / quantity,
        }
    end

    c_entries
  end

  def modifiers_to_c_entries(modifiers)
    return [] if modifiers.nil?

    modifiers.map do |m|
      {"sdm:ItemID" => m}
    end
  end

  def get_modifiers(line_item:)
    return [] if line_item.nil?

    item_bundles = line_item.dig(:item_detail_reference, :item_bundles)

    customization_options =
      get_customization_options(item_bundles: item_bundles)

    customization_option_item_ids =
      get_customization_option_item_ids(
        customization_options: customization_options,
      )

    customization_option_item_ids || []
  end

  def get_customization_options(item_bundles:)
    return [] if item_bundles.nil?

    item_bundles.map { |item_bundle|
      item_bundle.dig(:item, :customization_options)
    }.flatten
  end

  # Because we've used ID Numberifier customization option looks like this
  # {
  #  customization_option_item_ids: [ '123-456' ]
  # }
  # We need to extract only the part after the dash for SDM
  def get_customization_option_item_ids(customization_options:)
    return [] if customization_options.nil?

    customization_options.map do |customization_option|
      customization_option[:customization_option_item_ids]&.map { |customization_option_item_id|
        customization_option_item_id&.split("-")&.dig(1)
      }
    end
  end

  def payment_tender_id
    @order_dto.payment_type == "prepaid" ? @payment_config[:prepaid][:tender_id] : @payment_config[:cash][:tender_id]
  end

  def payment_sub_type
    @order_dto.payment_type == "prepaid" ? @payment_config[:prepaid][:sub_type] : @payment_config[:cash][:sub_type]
  end

  def payment_note
    @order_dto.payment_type == "prepaid" ? "Payment: Prepaid" : "Payment: Cash"
  end
end
