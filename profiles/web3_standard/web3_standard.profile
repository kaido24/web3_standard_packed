<?php
/**
 * Implements hook_form_FORM_ID_alter().
 *
 * Allows the profile to alter the site configuration form.
 */
if (!function_exists("system_form_install_configure_form_alter")) {
  function system_form_install_configure_form_alter(&$form, $form_state) {
    if (!empty($_SERVER['HTTP_HOST'])) {
      $mail = 'webmaster@' . $_SERVER['HTTP_HOST'];
    }
    else {
      $mail = 'webmaster@' . $_SERVER['SERVER_NAME'];
    }
    $form['site_information']['site_name']['#default_value'] = 'My website';
    $form['site_information']['site_mail']['#default_value'] =  $mail;
    $form['admin_account']['account']['name']['#default_value'] = 'admin';
    $form['admin_account']['account']['mail']['#default_value'] = $mail;
    $form['server_settings']['site_default_country']['#default_value'] =  'EE';
    $form['server_settings']['file_private_path'] = array(
      '#type' =>  'textfield',
      '#title' =>  st('Private file system path'),
      '#default_value' =>  '',
      '#weight' => 10,
      '#required' => TRUE,
    );
    $form['l10n_client_wrapper'] = array(
    '#type' => 'fieldset',
    '#title' => st('On-page translation and sharing'),
    '#collapsible' => FALSE,
  );
  $form['l10n_client_wrapper']['l10n_client_enable'] = array(
    '#type' => 'checkbox',
    '#default_value' => TRUE,
    '#title' => st('Enable on-page translation input'),
    '#description' => st('You can always disable this feature (the Localization client module) later, set up permissions or even turn it off per user.'),
  );
  $form['l10n_client_wrapper']['l10n_share_wrapper'] = array(
    '#type' => 'item',
    '#states' => array(
      'invisible' => array(
         'input[name="l10n_client_enable"]' => array('checked' => FALSE),
      ),
    ),
  );
  $form['l10n_client_wrapper']['l10n_share_wrapper']['l10n_client_sharing'] = array(
    '#type' => 'checkbox',
    '#default_value' => TRUE,
    '#title' => st('Share translations submitted with localize.drupal.org'),
  );

  // Load in l10n_client module (although it is not enabled yet). This makes
  // l10n_client_user_token available to us for use to generate the URL.
  module_load_include('module', 'l10n_client');
  $account = user_load(1);
  $server_link = 'http://localize.drupal.org?q=translate/remote/userkey/'. l10n_client_user_token($account);

  $form['l10n_client_wrapper']['l10n_share_wrapper']['l10n_client_key'] = array(
    '#type' => 'textfield',
    '#title' => st('Your personal key on localize.drupal.org'),
    '#description' => st('Each user account on the site should have their own localize.drupal.org key set up so the remote submission can be attributed properly. To get your key go to !server-link.', array('!server-link' => l($server_link, $server_link))),
    '#states' => array(
      'visible' => array(
         'input[name="l10n_client_sharing"]' => array('checked' => TRUE),
      ),

      // This is currently broken in core and makes the whole form element red.
      // See http://drupal.org/node/1017882
      /*'required' => array(
         'input[name="l10n_client_sharing"]' => array('checked' => TRUE),
      )*/
    ),
  );

  // Add both existing submit function and our submit function,
  // since adding just ours cancels the automated discovery of the original.
  $form['#submit'] = array('web3_standard_custom_submit', 'install_configure_form_submit');
  }
}
if (!function_exists("system_form_install_settings_form_alter")) {
  function system_form_install_settings_form_alter(&$form, $form_state) {
    $form['settings']['mysql']['advanced_options']['host']['#default_value'] = '127.0.0.1';
    $form['settings']['pgsql']['advanced_options']['host']['#default_value'] = '127.0.0.1';
  }
}

/**
 * Custom submit handler for the localized install.
 */
function web3_standard_custom_submit($form, &$form_state) {
  if ($form_state['values']['file_private_path']) {
    variable_set('file_private_path', $form_state['values']['file_private_path']);
  }
  if ($form_state['values']['l10n_client_enable']) {
    // Enable the module if the user did not disable it on purpose.
    module_enable(array('l10n_client'));
    if ($form_state['values']['l10n_client_sharing']) {
      // Enable sharing with localize.drupal.org as well.
      variable_set('l10n_client_use_server', 1);
      variable_set('l10n_client_server', 'http://localize.drupal.org');

      // User 1 was precreated before by Drupal, so we can just save our
      // additional info for that user.
      $account = user_load(1);
      $user_data = array('l10n_client_key' => $form_state['values']['l10n_client_key']);
      user_save($account, $user_data);
    }
  }
}

/**
 * Implement hook_install_tasks().
 */
function web3_standard_install_tasks($install_state) {
  // Determine whether translation import tasks will need to be performed.
  $needs_translations = count($install_state['locales']) > 1 && !empty($install_state['parameters']['locale']) && $install_state['parameters']['locale'] != 'en';

  return array(
    'web3_standard_import_translation' => array(
      'display_name' => st('Set up translations'),
      'display' => $needs_translations,
      'run' => $needs_translations ? INSTALL_TASK_RUN_IF_NOT_COMPLETED : INSTALL_TASK_SKIP,
      'type' => 'batch',
    ),
  );
}

/**
 * Implement hook_install_tasks_alter().
 *
 * Perform actions to set up the site for this profile.
 */
function web3_standard_install_tasks_alter(&$tasks, $install_state) {
  // Remove core steps for translation imports.
  unset($tasks['install_import_locales']);
  unset($tasks['install_import_locales_remaining']);
}

/**
 * Installation step callback.
 *
 * @param $install_state
 *   An array of information about the current installation state.
 */
 function web3_standard_import_translation(&$install_state) {
   // Enable installation language as default site language.
   include_once DRUPAL_ROOT . '/includes/locale.inc';
   $install_locale = $install_state['parameters']['locale'];
   locale_add_language($install_locale, NULL, NULL, NULL, '', NULL, 1, TRUE);

   // Fetch and batch the translations!
   module_load_include('fetch.inc', 'l10n_update');
   $options = _l10n_update_default_update_options();
   $last_checked = variable_get('l10n_update_last_check');
   if ($last_checked < REQUEST_TIME - L10N_UPDATE_STATUS_TTL) {
     l10n_update_clear_status();
     $batch = l10n_update_batch_update_build(array(), array($install_locale), $options);
   }
   else {
     $batch = l10n_update_batch_fetch_build(array(), array($install_locale), $options);
   }
   return $batch;
 }
