# This serializer is kept for compatability's sake until we are sure the
# SdmToDome catalog serializer is working well.
class Integrations::Sdm::Serializers::SdmToSwyft::CatalogSerializer
  def initialize(submenus:, items:, modifier_groups:, modifiers:, integration_catalog:, locale: :en)
    @locale = locale
    @integration_name = integration_catalog.integration_host.name || ""
    @integration_catalog_id = integration_catalog.id
    @locale_suffix = @locale == :ar ? "_un" : ""

    @submenus = submenus

    @modifier_groups = remove_not_visible_items(modifier_groups)
    @items = remove_not_visible_items(items)
    @modifiers = remove_not_visible_items(modifiers)

    # Since we have to remove categories and customization options that are full
    # of hidden items, we need to keep track of which of them we removed, so we
    # can also remove the references in other related items.
    # e.g. if a modifier group (customization option) is removed, we need to
    # remove it as the reference from the customization_option_item's
    # customization_id
    @removed_customization_option_ids = []

    # Keep track of modifier groups that we put a customization option item in
    # with default_selected: `true`
    #
    # Each modifier group should only have a single customization option item
    # with default_selected: `true`
    @modifier_group_ids_with_default_selection = []
  end

  # TODO: Probably re-write this function with performance in mind, it was
  # written more with readability in mind. It needlessly performs too many
  # loops over and over again due to how everything is broken up into many
  # functions.
  def menu
    result = {
      sets: [],
      items: [],
      bundles: [],
      products: [],
      item_sets: [],
      categories: [],
      bundle_sets: [],
      item_bundles: [],
      customization_options: [],
      customization_ingredients: [],
      customization_option_items: [],
      customization_ingredient_items: [],
    }

    # SDM Submenus
    # We add our own weight because submenus don't have ranks, and SDM
    # can have submenus full of items that are not supposed to be visible
    # so we hide them ourselves.
    categories = @submenus.map.with_index { |submenu, index|
      serialize_submenu_to_category(submenu: submenu, weight: index + 1)
    }
      .reject { |category| category[:product_ids].length == 0 }

    # Host-specific hacks because their categories have issues on their side
    categories = apply_category_hacks(categories)

    result[:categories] = categories

    # SDM Modifier Groups
    # We add our own weight because modifier groups don't have ranks, and SDM
    # can have modifier groups full of items that are not supposed to be visible
    # so we hide them ourselves (the customization option item IDs will be
    # empty in this case)
    customization_options = @modifier_groups.map.with_index { |mg, index|
      serialize_modifier_group_to_customization_option(
        modifier_group: mg, weight: index + 1
      )
    }

    # Keep track of the customization options that we're going to remove,
    # we need these to remove the reference to the remvoed customization option
    # in customization option items
    @removed_customization_option_ids = customization_options.select { |c|
      c[:customization_option_item_ids].length == 0
    }.map { |c| c[:id] }

    customization_options = customization_options.reject { |c|
      c[:customization_option_item_ids].length == 0
    }

    # Host-specific hacks because their customization options have issues on
    # their side
    customization_options = apply_customization_option_hacks(customization_options)

    result[:customization_options] = customization_options

    # SDM Items
    result[:items] = @items.map { |item| serialize_item_to_item(item: item) }

    result[:bundles] =
      @items.map { |item| serialize_item_to_bundle(item: item) }

    result[:item_bundles] =
      @items.map { |item| serialize_item_to_bundle_item(item: item) }

    products = @items.map { |item| serialize_item_to_product(item: item) }
    products = apply_product_hacks(products)
    result[:products] = products

    # SDM Modifiers
    result[:customization_option_items] =
      @modifiers.map { |modifier|
        serialize_modifier_to_customization_option_items(modifier: modifier)
      }
      .flatten

    result[:items] +=
      @modifiers.map { |modifier|
        serialize_modifier_to_item(modifier: modifier)
      }

    result
  end

  private

  # Takes in an a hash containing an elements.c_objects array and array
  # containing hashes with an 'id' key.
  #
  # Returns an array of IDs that are contained in both
  # hash_containing_c_objects and other_array
  def get_related_ids(hash_containing_c_objects:, other_array:)
    return [] if hash_containing_c_objects.nil? || other_array.nil?

    c_objects = hash_containing_c_objects.dig("elements", "c_object")

    return [] if c_objects.nil?

    # HACK: Deal with cases where SDM returns hashes when it should
    # return arrays, we really need a central serializer for their
    # properties to do this for us instead of having to handle it manually
    # in other classes.
    if c_objects.is_a?(Hash)
      c_objects = [c_objects]
    end

    c_objects.select { |c_object|
      other_array.find { |m| c_object["id"] == m["id"] }
    }.map { |c_object| c_object["id"].to_i }
  end

  # TODO: Perhaps move each domain into its own class
  #       (e.g. Sdm::Serializers::SubmenuItem)

  # Takes a submenu iterates through @items
  # Returns the IDs of items inside this submenu.
  def submenu_item_ids(submenu:)
    get_related_ids(hash_containing_c_objects: submenu, other_array: @items)
  end

  # Takes an item and iterates through @modifier_groups
  # Returns the IDs of modifier groups inside this item.
  def item_modifier_group_ids(item:)
    get_related_ids(
      hash_containing_c_objects: item, other_array: @modifier_groups
    )
  end

  # Takes a modifier group and iterates through @modifiers
  # Returns the IDs of modifiers inside this modifier group.
  def modifier_group_modifier_ids(modifier_group:)
    get_related_ids(
      hash_containing_c_objects: modifier_group, other_array: @modifiers
    ).map { |modifer_id| "#{modifier_group["id"].to_i}-#{modifer_id}" }
  end

  def modifier_groups(modifier:)
    return nil if modifier.nil? || @modifier_groups.nil?

    related_modifier_groups = []

    @modifier_groups.each do |modifier_group|
      modifier_group_modifiers = modifier_group.dig("elements", "c_object")

      # Skip to next modifier group if there are no modifiers
      next if modifier_group_modifiers.nil?

      # HACK: Deal with cases where SDM returns hashes when it should
      # return arrays, we really need a central serializer for their
      # properties to do this for us instead of having to handle it manually
      # in other classes.
      if modifier_group_modifiers.is_a?(Hash)
        modifier_group_modifiers = [modifier_group_modifiers]
      end

      modifier_group_modifiers.each do |modifier_group_modifier|
        if modifier_group_modifier["id"] == modifier["id"]
          related_modifier_groups << modifier_group
        end
      end
    end

    related_modifier_groups
  end

  def serialize_submenu_to_category(submenu:, weight:)
    {
      id: submenu["id"].to_i,
      name: localized_title(submenu),
      product_ids: submenu_item_ids(submenu: submenu),
      weight: weight.to_i,
    }
  end

  def serialize_item_to_product(item:)
    {
      id: item["id"].to_i,
      name: localized_name(item),
      images: [],
      weight: fix_sdm_rank(item["rank"]),
      description: localized_description(item),
      bundle_ids: [item["id"].to_i],
    }
  end

  def serialize_item_to_bundle(item:)
    {
      id: item["id"].to_i,
      name: localized_name(item),
      images: [],
      weight: fix_sdm_rank(item["rank"]),
      description: localized_description(item),
      item_bundle_ids: [item["id"].to_i],
    }
  end

  def serialize_item_to_bundle_item(item:)
    {
      id: item["id"].to_i,
      name: localized_name(item),
      price: item["price"].to_s,
      weight: fix_sdm_rank(item["rank"]),
      item_id: item["id"].to_i,
      bundle_id: item["id"].to_i,
    }
  end

  # Confusing name, but this serializes an SDM Item to a Dome Item
  def serialize_item_to_item(item:)
    customization_option_ids = item_modifier_group_ids(item: item)
      .uniq
      .reject { |item_modifier_group_id| @removed_customization_option_ids.include? item_modifier_group_id }

    {
      id: item["id"].to_i,
      images: [],
      customization_ingredient_ids: [],
      customization_option_ids: customization_option_ids,
    }
  end

  def serialize_modifier_group_to_customization_option(modifier_group:, weight:)
    customization_option_item_ids = modifier_group_modifier_ids(
      modifier_group: modifier_group
    ).uniq

    max_selection = fix_sdm_maximum(
      maximum: modifier_group["maximum"].to_i,
      customization_option_items_length: customization_option_item_ids.length
    )

    {
      id: modifier_group["id"].to_i,
      name: localized_title(modifier_group),
      images: [],
      max_selection: max_selection,
      min_selection: modifier_group["minimum"].to_i,
      weight: weight.to_i,
      customization_option_item_ids: customization_option_item_ids,
    }
  end

  def serialize_modifier_to_item(modifier:)
    {
      id: modifier["id"].to_i,
      images: [],
      customization_ingredient_ids: [],
      customization_option_ids: item_modifier_group_ids(item: modifier).uniq,
    }
  end

  def serialize_modifier_to_customization_option_items(modifier:)
    # Get the IDs of all the modifier groups this modifier belongs to
    related_modifier_groups = modifier_groups(modifier: modifier)
    customization_option_items = []

    # Remove customization options that we have manually removed ourselves
    related_modifier_groups = related_modifier_groups.reject { |modifier_group|
      @removed_customization_option_ids.include? modifier_group["id"].to_i
    }

    # Make a customization option item for each time a modifier is in a
    # modifier group, but with a customization option ID of the different
    # modifier groups.
    related_modifier_groups.each do |modifier_group|
      nested_modifiers = elements(modifier_group)
      nested_modifier = nested_modifiers.find { |nested_modifier| nested_modifier["id"].to_i == modifier["id"].to_i }

      modifier_price = nested_modifier["price_method"].to_i == 1 ? modifier["price"] : nested_modifier["price"]
      modifier_group_id = modifier_group["id"].to_i
      modifier_id = "#{modifier_group_id}-#{modifier["id"].to_i}"

      maximum = fix_sdm_maximum(
        maximum: modifier_group["maximum"].to_i,
        customization_option_items_length: related_modifier_groups.length
      )

      minimum = modifier_group["minimum"].to_i

      default_selected = false

      # Set default selected if an item is required (min & max both == 1) and
      # only if we haven't set a default selected customization option item in
      # this modifier group before.
      unless @modifier_group_ids_with_default_selection.include?(modifier_group_id)
        default_selected = minimum == 1 && maximum == 1

        if default_selected
          @modifier_group_ids_with_default_selection << modifier_group_id
        end
      end

      customization_option_items << {
        id: modifier_id,
        item_id: modifier["id"].to_i,
        customization_option_id: modifier_group_id,
        name: localized_name(modifier),
        price: modifier_price.to_s,
        weight: fix_sdm_rank(modifier["rank"]),
        # TODO: See if we can somehow get this from Modifier JSON
        default_selected: default_selected,
      }
    end

    customization_option_items
  end

  # This also works for modifiers becuase they're also of type CItem in SDM
  def remove_not_visible_items(items)
    not_visible_values = ["false", "0"]

    items&.reject { |item| not_visible_values.include?(item["visible"].to_s) }
  end

  def english_title_key
    "title"
  end

  def english_name_key
    "name"
  end

  def english_description_key
    "desc"
  end

  def localized_title_key
    "title#{@locale_suffix}"
  end

  def localized_name_key
    "name#{@locale_suffix}"
  end

  def localized_description_key
    "desc#{@locale_suffix}"
  end

  # The next 3 functions take in a hash and return the localized property or
  # the english one if the localized one doesn't exist
  def localized_title(sdm_object)
    sdm_object[localized_title_key] || sdm_object[english_title_key]
  end

  def localized_name(sdm_object)
    sdm_object[localized_name_key] || sdm_object[english_name_key]
  end

  def localized_description(sdm_object)
    sdm_object[localized_description_key] || sdm_object[english_description_key]
  end

  # SDM allows setting weights to negative values, this creates issues for us,
  # so we'll return their weight if it's greater than 1, or 1 if theirs is less
  # than 1.
  def fix_sdm_rank(rank)
    [rank.to_i, 1].max
  end

  # If SDM set the max to 0 (unlimited) or if their max is more than the
  # number of actual available items, we will cap the amount of items to
  # the number of available items
  def fix_sdm_maximum(maximum:, customization_option_items_length:)
    if maximum == 0 || maximum > customization_option_items_length
      maximum = customization_option_items_length
    end

    maximum
  end

  def hacker
    if @integration_name.include?("Kudu")
      Integrations::Sdm::Serializers::Hacks::Swyft::Kudu.new
    else
      Integrations::Sdm::Serializers::Hacks::BaseHacker.new
    end
  end

  def apply_category_hacks(categories)
    hacker.apply_category_hacks(categories: categories, locale: @locale)
  end

  def apply_customization_option_hacks(customization_options)
    hacker.apply_customization_option_hacks(customization_options)
  end

  def apply_product_hacks(products)
    hacker.apply_product_hacks(
      products: products,
      integration_catalog_id: @integration_catalog_id
    )
  end

  def elements(item)
    c_object = item.dig("elements", "c_object")

    # Skip to next modifier group if there are no modifiers
    return [] if c_object.nil?

    # HACK: Deal with cases where SDM returns hashes when it should
    # return arrays, we really need a central serializer for their
    # properties to do this for us instead of having to handle it manually
    # in other classes.
    if c_object.is_a?(Hash)
      return [c_object]
    end
    c_object
  end
end
