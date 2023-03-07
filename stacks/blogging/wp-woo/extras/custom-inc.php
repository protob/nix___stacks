<?php
function brand_init()
{
    register_taxonomy("brand", ["product"], [
        "hierarchical"          => false,
        "public"                => true,
        "show_in_nav_menus"     => true,
        "show_ui"               => true,
        "show_admin_column"     => false,
        "query_var"             => true,
        "rewrite"               => true,
        "capabilities"          => [
            "manage_terms" => "edit_posts",
            "edit_terms"   => "edit_posts",
            "delete_terms" => "edit_posts",
            "assign_terms" => "edit_posts",
        ],
        "labels"                => [
            "name"                       => __("Brands", "YOUR-TEXTDOMAIN"),
            "singular_name"              => _x("Brand", "taxonomy general name", "YOUR-TEXTDOMAIN"),
            "search_items"               => __("Search Brands", "YOUR-TEXTDOMAIN"),
            "popular_items"              => __("Popular Brands", "YOUR-TEXTDOMAIN"),
            "all_items"                  => __("All Brands", "YOUR-TEXTDOMAIN"),
            "parent_item"                => __("Parent Brand", "YOUR-TEXTDOMAIN"),
            "parent_item_colon"          => __("Parent Brand:", "YOUR-TEXTDOMAIN"),
            "edit_item"                  => __("Edit Brand", "YOUR-TEXTDOMAIN"),
            "update_item"                => __("Update Brand", "YOUR-TEXTDOMAIN"),
            "view_item"                  => __("View Brand", "YOUR-TEXTDOMAIN"),
            "add_new_item"               => __("Add New Brand", "YOUR-TEXTDOMAIN"),
            "new_item_name"              => __("New Brand", "YOUR-TEXTDOMAIN"),
            "separate_items_with_commas" => __("Separate brands with commas", "YOUR-TEXTDOMAIN"),
            "add_or_remove_items"        => __("Add or remove brands", "YOUR-TEXTDOMAIN"),
            "choose_from_most_used"      => __("Choose from the most used brands", "YOUR-TEXTDOMAIN"),
            "not_found"                  => __("No brands found.", "YOUR-TEXTDOMAIN"),
            "no_terms"                   => __("No brands", "YOUR-TEXTDOMAIN"),
            "menu_name"                  => __("Brands", "YOUR-TEXTDOMAIN"),
            "items_list_navigation"      => __("Brands list navigation", "YOUR-TEXTDOMAIN"),
            "items_list"                 => __("Brands list", "YOUR-TEXTDOMAIN"),
            "most_used"                  => _x("Most Used", "brand", "YOUR-TEXTDOMAIN"),
            "back_to_items"              => __("&larr; Back to Brands", "YOUR-TEXTDOMAIN"),
        ],
        "show_in_rest"          => true,
        "rest_base"             => "brand",
        "rest_controller_class" => "WP_REST_Terms_Controller",
    ]);
}

add_action("init", "brand_init");


function brand_updated_messages($messages)
{
    $messages["brand"] = [
        0 => "", // Unused. Messages start at index 1.
        1 => __("Brand added.", "YOUR-TEXTDOMAIN"),
        2 => __("Brand deleted.", "YOUR-TEXTDOMAIN"),
        3 => __("Brand updated.", "YOUR-TEXTDOMAIN"),
        4 => __("Brand not added.", "YOUR-TEXTDOMAIN"),
        5 => __("Brand not updated.", "YOUR-TEXTDOMAIN"),
        6 => __("Brands deleted.", "YOUR-TEXTDOMAIN"),
    ];

    return $messages;
}

add_filter("term_updated_messages", "brand_updated_messages");





// Add the "Brand" column to the product list table
add_filter("manage_edit-product_columns", "add_brand_column");
function add_brand_column($columns)
{
    $columns["brand"] = __("Brand");
    return $columns;
}


// Populate the "Brand" column with the taxonomy term
add_action("manage_product_posts_custom_column", "populate_brand_column", 10, 2);
function populate_brand_column($column, $post_id)
{
    if ($column == "brand") {
        $terms = get_the_terms($post_id, "brand");
        if (!empty($terms)) {
            foreach ($terms as $term) {
                echo "<a href=\"" . esc_url(admin_url("edit.php?brand=" . $term->slug . "&post_type=product")) . "\">" . $term->name . "</a><br/>";
            }
        } else {
            echo '<span class="na">&ndash;</span>';
        }
    }
}


function set_permalink_structure()
{
    global $wp_rewrite;
    $wp_rewrite->set_permalink_structure('/%postname%/');
    $wp_rewrite->flush_rules();
}
add_action('init', 'set_permalink_structure');
