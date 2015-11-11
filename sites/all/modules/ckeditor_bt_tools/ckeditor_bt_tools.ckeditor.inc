<?php

/**
 * @file
 * Provides Media: WYSIWYG integration for CKEditor.
 */

/**
 * Implements hook_ckeditor_plugin_alter().
 */
function ckeditor_bt_tools_ckeditor_plugin_alter(&$plugins) {
  // Override the default CKEditor Media plugin.
  $plugins['bt_table'] = array(
    'name' => 'bt_table',
    'desc' => t('Plugin for adding Bootstrap table attributes'),
    'path' => '%base_path%' . drupal_get_path('module', 'ckeditor_bt_tools') . '/plugins/bt_table/',
    'buttons' => array(
      'Table' => array(
        'icon' => 'icons/table.png',
        'label' => 'Add table',
      ),
    ),
  'default' => 't',
  );
  $plugins['btquicktable'] = array(
    'name' => 'btquicktable',
    'desc' => t('Plugin for adding Bootstrap table attributes quickly'),
    'path' => '%base_path%' . drupal_get_path('module', 'ckeditor_bt_tools') . '/plugins/btquicktable/',
    'buttons' => array(
      'Table' => array(
        'icon' => 'icons/table.png',
        'label' => 'Add table',
      ),
    ),
    'default' => 'f',
  );
  $plugins['btgrid'] = array(
    'name' => 'btgrid',
    'desc' => t('Plugin for adding Bootstrap Grid'),
    'path' => '%base_path%' . drupal_get_path('module', 'ckeditor_btgrid') . '/js/btgrid/',
    'buttons' => array(
      'btgrid' => array(
        'icon' => 'icons/btgrid.png',
        'label' => t('Add Bootstrap grid'),
      ),
    ),
    'default' => 't',
  );
}
