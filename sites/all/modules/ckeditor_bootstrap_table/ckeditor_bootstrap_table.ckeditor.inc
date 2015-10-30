<?php

/**
 * @file
 * Provides Media: WYSIWYG integration for CKEditor.
 */

/**
 * Implements hook_ckeditor_plugin_alter().
 */
function ckeditor_bootstrap_table_ckeditor_plugin_alter(&$plugins) {
  // Override the default CKEditor Media plugin.
  $plugins['bt_table'] = array(
    'name' => 'bt_table',
    'desc' => t('Plugin for adding Bootstrap table attributes'),
    'path' => '%base_path%' . drupal_get_path('module', 'ckeditor_bootstrap_table') . '/js/plugins/bt_table/',
    'buttons' => array(
      'Table' => array(
        'icon' => 'icons/table.png',
        'label' => 'Add table',
      ),
    ),
  'default' => 'f',
  );
  $plugins['btquicktable'] = array(
    'name' => 'btquicktable',
    'desc' => t('Plugin for adding Bootstrap table attributes quickly'),
    'path' => '%base_path%' . drupal_get_path('module', 'ckeditor_bootstrap_table') . '/js/plugins/btquicktable/',
    'buttons' => array(
      'Table' => array(
       // 'icon' => 'icons/table.png',
        'label' => 'Add table',
      ),
    ),
    'default' => 'f',
  );
}
