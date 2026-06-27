#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "todoapp_rails");
const clientOutputDir = join(root, "test", ".generated", "todoapp_rails_client");
const exampleDir = join(root, "examples", "todoapp_rails");
const invalidSourceDir = join(root, "test", ".generated", "todoapp_rails_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "todoapp_rails_invalid_out");
const rawErbInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_raw_erb_invalid_src");
const rawErbInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_raw_erb_invalid_out");
const typedTemplateInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_template_invalid_src");
const typedTemplateInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_template_invalid_out");
const typedPartialInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_partial_invalid_src");
const typedPartialInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_partial_invalid_out");
const checkedAttrSourceDir = join(root, "test", ".generated", "todoapp_rails_checked_attr_src");
const checkedAttrOutputDir = join(root, "test", ".generated", "todoapp_rails_checked_attr_out");
const checkedAttrInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_checked_attr_invalid_src");
const checkedAttrInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_checked_attr_invalid_out");
const pictureTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_picture_tag_invalid_src");
const pictureTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_picture_tag_invalid_out");
const faviconLinkTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_favicon_link_tag_invalid_src");
const faviconLinkTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_favicon_link_tag_invalid_out");
const preloadLinkTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_preload_link_tag_invalid_src");
const preloadLinkTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_preload_link_tag_invalid_out");
const javascriptIncludeTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_javascript_include_tag_invalid_src");
const javascriptIncludeTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_javascript_include_tag_invalid_out");
const javascriptTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_javascript_tag_invalid_src");
const javascriptTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_javascript_tag_invalid_out");
const autoDiscoveryLinkTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_auto_discovery_link_tag_invalid_src");
const autoDiscoveryLinkTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_auto_discovery_link_tag_invalid_out");
const audioTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_audio_tag_invalid_src");
const audioTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_audio_tag_invalid_out");
const videoTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_video_tag_invalid_src");
const videoTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_video_tag_invalid_out");
const phoneToInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_phone_to_invalid_src");
const phoneToInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_phone_to_invalid_out");
const smsToInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_sms_to_invalid_src");
const smsToInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_sms_to_invalid_out");
const excerptInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_excerpt_invalid_src");
const excerptInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_excerpt_invalid_out");
const highlightInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_highlight_invalid_src");
const highlightInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_highlight_invalid_out");
const wordWrapInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_word_wrap_invalid_src");
const wordWrapInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_word_wrap_invalid_out");
const sanitizeInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_sanitize_invalid_src");
const sanitizeInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_sanitize_invalid_out");
const sanitizeCssInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_sanitize_css_invalid_src");
const sanitizeCssInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_sanitize_css_invalid_out");
const stripTagsInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_strip_tags_invalid_src");
const stripTagsInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_strip_tags_invalid_out");
const stripLinksInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_strip_links_invalid_src");
const stripLinksInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_strip_links_invalid_out");
const toSentenceInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_to_sentence_invalid_src");
const toSentenceInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_to_sentence_invalid_out");
const escapeOnceInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_escape_once_invalid_src");
const escapeOnceInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_escape_once_invalid_out");
const cdataSectionInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_cdata_section_invalid_src");
const cdataSectionInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_cdata_section_invalid_out");
const safeJoinInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_safe_join_invalid_src");
const safeJoinInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_safe_join_invalid_out");
const tokenListInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_token_list_invalid_src");
const tokenListInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_token_list_invalid_out");
const classNamesInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_class_names_invalid_src");
const classNamesInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_class_names_invalid_out");
const cycleInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_cycle_invalid_src");
const cycleInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_cycle_invalid_out");
const currentCycleInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_current_cycle_invalid_src");
const currentCycleInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_current_cycle_invalid_out");
const resetCycleInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_reset_cycle_invalid_src");
const resetCycleInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_reset_cycle_invalid_out");
const timeAgoInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_time_ago_invalid_src");
const timeAgoInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_time_ago_invalid_out");
const distanceOfTimeInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_distance_of_time_invalid_src");
const distanceOfTimeInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_distance_of_time_invalid_out");
const timeTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_time_tag_invalid_src");
const timeTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_time_tag_invalid_out");
const numberToPhoneInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_number_to_phone_invalid_src");
const numberToPhoneInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_number_to_phone_invalid_out");
const numberToHumanSizeInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_number_to_human_size_invalid_src");
const numberToHumanSizeInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_number_to_human_size_invalid_out");
const numberWithPrecisionInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_number_with_precision_invalid_src");
const numberWithPrecisionInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_number_with_precision_invalid_out");
const numberWithDelimiterInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_number_with_delimiter_invalid_src");
const numberWithDelimiterInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_number_with_delimiter_invalid_out");
const buttonTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_button_tag_invalid_src");
const buttonTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_button_tag_invalid_out");
const submitTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_submit_tag_invalid_src");
const submitTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_submit_tag_invalid_out");
const textFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_text_field_tag_invalid_src");
const textFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_text_field_tag_invalid_out");
const searchFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_search_field_tag_invalid_src");
const searchFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_search_field_tag_invalid_out");
const emailFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_email_field_tag_invalid_src");
const emailFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_email_field_tag_invalid_out");
const telephoneFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_telephone_field_tag_invalid_src");
const telephoneFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_telephone_field_tag_invalid_out");
const urlFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_url_field_tag_invalid_src");
const urlFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_url_field_tag_invalid_out");
const numberFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_number_field_tag_invalid_src");
const numberFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_number_field_tag_invalid_out");
const rangeFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_range_field_tag_invalid_src");
const rangeFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_range_field_tag_invalid_out");
const colorFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_color_field_tag_invalid_src");
const colorFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_color_field_tag_invalid_out");
const dateFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_date_field_tag_invalid_src");
const dateFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_date_field_tag_invalid_out");
const timeFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_time_field_tag_invalid_src");
const timeFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_time_field_tag_invalid_out");
const datetimeFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_datetime_field_tag_invalid_src");
const datetimeFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_datetime_field_tag_invalid_out");
const monthFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_month_field_tag_invalid_src");
const monthFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_month_field_tag_invalid_out");
const weekFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_week_field_tag_invalid_src");
const weekFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_week_field_tag_invalid_out");
const passwordFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_password_field_tag_invalid_src");
const passwordFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_password_field_tag_invalid_out");
const hiddenFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_hidden_field_tag_invalid_src");
const hiddenFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_hidden_field_tag_invalid_out");
const fileFieldTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_file_field_tag_invalid_src");
const fileFieldTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_file_field_tag_invalid_out");
const textAreaTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_text_area_tag_invalid_src");
const textAreaTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_text_area_tag_invalid_out");
const checkBoxTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_check_box_tag_invalid_src");
const checkBoxTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_check_box_tag_invalid_out");
const radioButtonTagInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_radio_button_tag_invalid_src");
const radioButtonTagInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_radio_button_tag_invalid_out");
const formSelectInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_form_select_invalid_src");
const formSelectInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_form_select_invalid_out");
const formSearchFieldInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_form_search_field_invalid_src");
const formSearchFieldInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_form_search_field_invalid_out");
const formEmailFieldInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_form_email_field_invalid_src");
const formEmailFieldInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_form_email_field_invalid_out");
const typedRouteInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_route_invalid_src");
const typedRouteInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_route_invalid_out");
const typedRouteParamInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_route_param_invalid_src");
const typedRouteParamInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_route_param_invalid_out");
const typedFormInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_form_invalid_src");
const typedFormInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_form_invalid_out");
const typedSlotInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_slot_invalid_src");
const typedSlotInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_slot_invalid_out");
const templateRefInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_template_ref_invalid_src");
const templateRefInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_template_ref_invalid_out");
const templatePathInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_template_path_invalid_src");
const templatePathInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_template_path_invalid_out");
const templateBackslashPathInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_template_backslash_path_invalid_src");
const templateBackslashPathInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_template_backslash_path_invalid_out");
const rawLayoutInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_raw_layout_invalid_src");
const rawLayoutInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_raw_layout_invalid_out");
const typedFieldInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_field_invalid_src");
const typedFieldInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_field_invalid_out");
const typedParamsInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_params_invalid_src");
const typedParamsInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_params_invalid_out");
const typedParamsUnknownSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_params_unknown_src");
const typedParamsUnknownOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_params_unknown_out");
const typedRequestParamsUnknownSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_request_params_unknown_src");
const typedRequestParamsUnknownOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_request_params_unknown_out");
const migrationDuplicateTableSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_table_src");
const migrationDuplicateTableOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_table_out");
const migrationDuplicateFileSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_file_src");
const migrationDuplicateFileOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_file_out");
const migrationNonModelSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_non_model_src");
const migrationNonModelOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_non_model_out");
const migrationBadTimestampSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_bad_timestamp_src");
const migrationBadTimestampOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_bad_timestamp_out");
const migrationUnknownOptionSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_option_src");
const migrationUnknownOptionOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_option_out");
const migrationBadOperationSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_bad_operation_src");
const migrationBadOperationOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_bad_operation_out");
const migrationUnsafeSqlSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_sql_src");
const migrationUnsafeSqlOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_sql_out");
const migrationDuplicateTimestampSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_timestamp_src");
const migrationDuplicateTimestampOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_timestamp_out");
const migrationForeignKeyOrderSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_foreign_key_order_src");
const migrationForeignKeyOrderOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_foreign_key_order_out");
const migrationIrreversibleOperationSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_irreversible_operation_src");
const migrationIrreversibleOperationOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_irreversible_operation_out");
const migrationUnknownTableSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_table_src");
const migrationUnknownTableOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_table_out");
const migrationUnknownColumnSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_column_src");
const migrationUnknownColumnOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_column_out");
const migrationUnsafeIndexNameSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_index_name_src");
const migrationUnsafeIndexNameOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_index_name_out");
const migrationUnsafeForeignKeyNameSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_foreign_key_name_src");
const migrationUnsafeForeignKeyNameOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_foreign_key_name_out");
const migrationUnsafeCheckConstraintNameSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_check_constraint_name_src");
const migrationUnsafeCheckConstraintNameOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_check_constraint_name_out");
const migrationExternalTableSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_external_table_src");
const migrationExternalTableOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_external_table_out");
const migrationUnsafeExternalTableSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_external_table_src");
const migrationUnsafeExternalTableOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_external_table_out");
const migrationDropTableSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_drop_table_src");
const migrationDropTableOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_drop_table_out");
const migrationSnapshotOpsSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_snapshot_ops_src");
const migrationSnapshotOpsOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_snapshot_ops_out");
const migrationHistoricalAddColumnSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_historical_add_column_src");
const migrationHistoricalAddColumnOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_historical_add_column_out");
const migrationDuplicateAddColumnSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_add_column_src");
const migrationDuplicateAddColumnOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_add_column_out");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    env: options.env ?? process.env,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0 && !options.allowFailure) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

function compileTodoClient() {
  const clientBuild = readFileSync(join(exampleDir, "build-client.hxml"), "utf8");
  for (const expected of [
    "--macro genes.Generator.use()",
    "--macro reflaxe.js.Async.enable()",
  ]) {
    if (!clientBuild.includes(expected)) {
      console.error(`todoapp_rails client build is missing expected async/Genes setup: ${expected}`);
      process.exit(1);
    }
  }
  run("haxe", [join(exampleDir, "build-client.hxml")]);
  for (const file of [
    "_todo_client_tmp.js",
    "client/TodoClient.js",
    "reflaxe/js/Async.js",
    "rails/turbo/Turbo.js",
    "genes/Register.js",
  ]) {
    if (!existsSync(join(clientOutputDir, file))) {
      console.error(`todoapp_rails client Genes output missing expected file: ${file}`);
      process.exit(1);
    }
  }
  const todoClient = readFileSync(join(clientOutputDir, "client", "TodoClient.js"), "utf8");
  for (const snippet of [
    "static async hideAfterDelay",
    "await Async.delay(milliseconds)",
    "static async removeClassAfterDelay",
    "Turbo.addFetchRequestHeader",
  ]) {
    if (!todoClient.includes(snippet)) {
      console.error(`todoapp_rails client output missing async/await snippet: ${snippet}`);
      process.exit(1);
    }
  }
  for (const forbidden of [
    "document.createElement(\"li\")",
    ".innerHTML =",
    "insertBefore(item",
    "static async syncChatPanel",
    "await Async.delay(0)",
    "Consumer.subscribe(consumer, \"Channels::ChatMessagesChannel\"",
    "Turbo.renderStreamMessage(Turbo.stream(\"prepend\", \"railshx-chat-list\"",
    "static escapeHtml(value)",
  ]) {
    if (todoClient.includes(forbidden)) {
      console.error(`todoapp_rails client output should use Turbo Stream rendering instead of low-level DOM mutation: ${forbidden}`);
      process.exit(1);
    }
  }
  if (todoClient.includes("__async_marker__")) {
    console.error("todoapp_rails client output leaked the Genes async marker.");
    process.exit(1);
  }
}

rmSync(outputDir, { force: true, recursive: true });
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });
rmSync(rawErbInvalidSourceDir, { force: true, recursive: true });
rmSync(rawErbInvalidOutputDir, { force: true, recursive: true });
rmSync(typedTemplateInvalidSourceDir, { force: true, recursive: true });
rmSync(typedTemplateInvalidOutputDir, { force: true, recursive: true });
rmSync(typedPartialInvalidSourceDir, { force: true, recursive: true });
rmSync(typedPartialInvalidOutputDir, { force: true, recursive: true });
rmSync(checkedAttrSourceDir, { force: true, recursive: true });
rmSync(checkedAttrOutputDir, { force: true, recursive: true });
rmSync(checkedAttrInvalidSourceDir, { force: true, recursive: true });
rmSync(checkedAttrInvalidOutputDir, { force: true, recursive: true });
rmSync(pictureTagInvalidSourceDir, { force: true, recursive: true });
rmSync(pictureTagInvalidOutputDir, { force: true, recursive: true });
rmSync(faviconLinkTagInvalidSourceDir, { force: true, recursive: true });
rmSync(faviconLinkTagInvalidOutputDir, { force: true, recursive: true });
rmSync(preloadLinkTagInvalidSourceDir, { force: true, recursive: true });
rmSync(preloadLinkTagInvalidOutputDir, { force: true, recursive: true });
rmSync(javascriptIncludeTagInvalidSourceDir, { force: true, recursive: true });
rmSync(javascriptIncludeTagInvalidOutputDir, { force: true, recursive: true });
rmSync(javascriptTagInvalidSourceDir, { force: true, recursive: true });
rmSync(javascriptTagInvalidOutputDir, { force: true, recursive: true });
rmSync(autoDiscoveryLinkTagInvalidSourceDir, { force: true, recursive: true });
rmSync(autoDiscoveryLinkTagInvalidOutputDir, { force: true, recursive: true });
rmSync(audioTagInvalidSourceDir, { force: true, recursive: true });
rmSync(audioTagInvalidOutputDir, { force: true, recursive: true });
rmSync(videoTagInvalidSourceDir, { force: true, recursive: true });
rmSync(videoTagInvalidOutputDir, { force: true, recursive: true });
rmSync(phoneToInvalidSourceDir, { force: true, recursive: true });
rmSync(phoneToInvalidOutputDir, { force: true, recursive: true });
rmSync(smsToInvalidSourceDir, { force: true, recursive: true });
rmSync(smsToInvalidOutputDir, { force: true, recursive: true });
rmSync(excerptInvalidSourceDir, { force: true, recursive: true });
rmSync(excerptInvalidOutputDir, { force: true, recursive: true });
rmSync(highlightInvalidSourceDir, { force: true, recursive: true });
rmSync(highlightInvalidOutputDir, { force: true, recursive: true });
rmSync(wordWrapInvalidSourceDir, { force: true, recursive: true });
rmSync(wordWrapInvalidOutputDir, { force: true, recursive: true });
rmSync(sanitizeInvalidSourceDir, { force: true, recursive: true });
rmSync(sanitizeInvalidOutputDir, { force: true, recursive: true });
rmSync(sanitizeCssInvalidSourceDir, { force: true, recursive: true });
rmSync(sanitizeCssInvalidOutputDir, { force: true, recursive: true });
rmSync(stripTagsInvalidSourceDir, { force: true, recursive: true });
rmSync(stripTagsInvalidOutputDir, { force: true, recursive: true });
rmSync(stripLinksInvalidSourceDir, { force: true, recursive: true });
rmSync(stripLinksInvalidOutputDir, { force: true, recursive: true });
rmSync(toSentenceInvalidSourceDir, { force: true, recursive: true });
rmSync(toSentenceInvalidOutputDir, { force: true, recursive: true });
rmSync(escapeOnceInvalidSourceDir, { force: true, recursive: true });
rmSync(escapeOnceInvalidOutputDir, { force: true, recursive: true });
rmSync(cdataSectionInvalidSourceDir, { force: true, recursive: true });
rmSync(cdataSectionInvalidOutputDir, { force: true, recursive: true });
rmSync(safeJoinInvalidSourceDir, { force: true, recursive: true });
rmSync(safeJoinInvalidOutputDir, { force: true, recursive: true });
rmSync(tokenListInvalidSourceDir, { force: true, recursive: true });
rmSync(tokenListInvalidOutputDir, { force: true, recursive: true });
rmSync(classNamesInvalidSourceDir, { force: true, recursive: true });
rmSync(classNamesInvalidOutputDir, { force: true, recursive: true });
rmSync(cycleInvalidSourceDir, { force: true, recursive: true });
rmSync(cycleInvalidOutputDir, { force: true, recursive: true });
rmSync(currentCycleInvalidSourceDir, { force: true, recursive: true });
rmSync(currentCycleInvalidOutputDir, { force: true, recursive: true });
rmSync(resetCycleInvalidSourceDir, { force: true, recursive: true });
rmSync(resetCycleInvalidOutputDir, { force: true, recursive: true });
rmSync(timeAgoInvalidSourceDir, { force: true, recursive: true });
rmSync(timeAgoInvalidOutputDir, { force: true, recursive: true });
rmSync(distanceOfTimeInvalidSourceDir, { force: true, recursive: true });
rmSync(distanceOfTimeInvalidOutputDir, { force: true, recursive: true });
rmSync(timeTagInvalidSourceDir, { force: true, recursive: true });
rmSync(timeTagInvalidOutputDir, { force: true, recursive: true });
rmSync(numberToPhoneInvalidSourceDir, { force: true, recursive: true });
rmSync(numberToPhoneInvalidOutputDir, { force: true, recursive: true });
rmSync(numberToHumanSizeInvalidSourceDir, { force: true, recursive: true });
rmSync(numberToHumanSizeInvalidOutputDir, { force: true, recursive: true });
rmSync(numberWithPrecisionInvalidSourceDir, { force: true, recursive: true });
rmSync(numberWithPrecisionInvalidOutputDir, { force: true, recursive: true });
rmSync(numberWithDelimiterInvalidSourceDir, { force: true, recursive: true });
rmSync(numberWithDelimiterInvalidOutputDir, { force: true, recursive: true });
rmSync(buttonTagInvalidSourceDir, { force: true, recursive: true });
rmSync(buttonTagInvalidOutputDir, { force: true, recursive: true });
rmSync(submitTagInvalidSourceDir, { force: true, recursive: true });
rmSync(submitTagInvalidOutputDir, { force: true, recursive: true });
rmSync(textFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(textFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(searchFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(searchFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(emailFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(emailFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(telephoneFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(telephoneFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(urlFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(urlFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(numberFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(numberFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(rangeFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(rangeFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(colorFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(colorFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(dateFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(dateFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(timeFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(timeFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(datetimeFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(datetimeFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(monthFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(monthFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(weekFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(weekFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(passwordFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(passwordFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(hiddenFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(hiddenFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(fileFieldTagInvalidSourceDir, { force: true, recursive: true });
rmSync(fileFieldTagInvalidOutputDir, { force: true, recursive: true });
rmSync(textAreaTagInvalidSourceDir, { force: true, recursive: true });
rmSync(textAreaTagInvalidOutputDir, { force: true, recursive: true });
rmSync(checkBoxTagInvalidSourceDir, { force: true, recursive: true });
rmSync(checkBoxTagInvalidOutputDir, { force: true, recursive: true });
rmSync(radioButtonTagInvalidSourceDir, { force: true, recursive: true });
rmSync(radioButtonTagInvalidOutputDir, { force: true, recursive: true });
rmSync(formSelectInvalidSourceDir, { force: true, recursive: true });
rmSync(formSelectInvalidOutputDir, { force: true, recursive: true });
rmSync(formSearchFieldInvalidSourceDir, { force: true, recursive: true });
rmSync(formSearchFieldInvalidOutputDir, { force: true, recursive: true });
rmSync(formEmailFieldInvalidSourceDir, { force: true, recursive: true });
rmSync(formEmailFieldInvalidOutputDir, { force: true, recursive: true });
rmSync(typedRouteInvalidSourceDir, { force: true, recursive: true });
rmSync(typedRouteInvalidOutputDir, { force: true, recursive: true });
rmSync(typedRouteParamInvalidSourceDir, { force: true, recursive: true });
rmSync(typedRouteParamInvalidOutputDir, { force: true, recursive: true });
rmSync(typedFormInvalidSourceDir, { force: true, recursive: true });
rmSync(typedFormInvalidOutputDir, { force: true, recursive: true });
rmSync(typedSlotInvalidSourceDir, { force: true, recursive: true });
rmSync(typedSlotInvalidOutputDir, { force: true, recursive: true });
rmSync(templateRefInvalidSourceDir, { force: true, recursive: true });
rmSync(templateRefInvalidOutputDir, { force: true, recursive: true });
rmSync(templatePathInvalidSourceDir, { force: true, recursive: true });
rmSync(templatePathInvalidOutputDir, { force: true, recursive: true });
rmSync(templateBackslashPathInvalidSourceDir, { force: true, recursive: true });
rmSync(templateBackslashPathInvalidOutputDir, { force: true, recursive: true });
rmSync(rawLayoutInvalidSourceDir, { force: true, recursive: true });
rmSync(rawLayoutInvalidOutputDir, { force: true, recursive: true });
rmSync(typedFieldInvalidSourceDir, { force: true, recursive: true });
rmSync(typedFieldInvalidOutputDir, { force: true, recursive: true });
rmSync(typedParamsInvalidSourceDir, { force: true, recursive: true });
rmSync(typedParamsInvalidOutputDir, { force: true, recursive: true });
rmSync(typedParamsUnknownSourceDir, { force: true, recursive: true });
rmSync(typedParamsUnknownOutputDir, { force: true, recursive: true });
rmSync(typedRequestParamsUnknownSourceDir, { force: true, recursive: true });
rmSync(typedRequestParamsUnknownOutputDir, { force: true, recursive: true });
rmSync(migrationDuplicateTableSourceDir, { force: true, recursive: true });
rmSync(migrationDuplicateTableOutputDir, { force: true, recursive: true });
rmSync(migrationDuplicateFileSourceDir, { force: true, recursive: true });
rmSync(migrationDuplicateFileOutputDir, { force: true, recursive: true });
rmSync(migrationNonModelSourceDir, { force: true, recursive: true });
rmSync(migrationNonModelOutputDir, { force: true, recursive: true });
rmSync(migrationBadTimestampSourceDir, { force: true, recursive: true });
rmSync(migrationBadTimestampOutputDir, { force: true, recursive: true });
rmSync(migrationUnknownOptionSourceDir, { force: true, recursive: true });
rmSync(migrationUnknownOptionOutputDir, { force: true, recursive: true });
rmSync(migrationBadOperationSourceDir, { force: true, recursive: true });
rmSync(migrationBadOperationOutputDir, { force: true, recursive: true });
rmSync(migrationUnsafeSqlSourceDir, { force: true, recursive: true });
rmSync(migrationUnsafeSqlOutputDir, { force: true, recursive: true });
rmSync(migrationDuplicateTimestampSourceDir, { force: true, recursive: true });
rmSync(migrationDuplicateTimestampOutputDir, { force: true, recursive: true });
rmSync(migrationForeignKeyOrderSourceDir, { force: true, recursive: true });
rmSync(migrationForeignKeyOrderOutputDir, { force: true, recursive: true });
rmSync(migrationIrreversibleOperationSourceDir, { force: true, recursive: true });
rmSync(migrationIrreversibleOperationOutputDir, { force: true, recursive: true });
rmSync(migrationUnknownTableSourceDir, { force: true, recursive: true });
rmSync(migrationUnknownTableOutputDir, { force: true, recursive: true });
rmSync(migrationUnknownColumnSourceDir, { force: true, recursive: true });
rmSync(migrationUnknownColumnOutputDir, { force: true, recursive: true });
rmSync(migrationUnsafeIndexNameSourceDir, { force: true, recursive: true });
rmSync(migrationUnsafeIndexNameOutputDir, { force: true, recursive: true });
rmSync(migrationUnsafeForeignKeyNameSourceDir, { force: true, recursive: true });
rmSync(migrationUnsafeForeignKeyNameOutputDir, { force: true, recursive: true });
rmSync(migrationUnsafeCheckConstraintNameSourceDir, { force: true, recursive: true });
rmSync(migrationUnsafeCheckConstraintNameOutputDir, { force: true, recursive: true });
rmSync(migrationExternalTableSourceDir, { force: true, recursive: true });
rmSync(migrationExternalTableOutputDir, { force: true, recursive: true });
rmSync(migrationUnsafeExternalTableSourceDir, { force: true, recursive: true });
rmSync(migrationUnsafeExternalTableOutputDir, { force: true, recursive: true });
rmSync(migrationDropTableSourceDir, { force: true, recursive: true });
rmSync(migrationDropTableOutputDir, { force: true, recursive: true });
rmSync(migrationSnapshotOpsSourceDir, { force: true, recursive: true });
rmSync(migrationSnapshotOpsOutputDir, { force: true, recursive: true });
rmSync(migrationHistoricalAddColumnSourceDir, { force: true, recursive: true });
rmSync(migrationHistoricalAddColumnOutputDir, { force: true, recursive: true });
rmSync(migrationDuplicateAddColumnSourceDir, { force: true, recursive: true });
rmSync(migrationDuplicateAddColumnOutputDir, { force: true, recursive: true });
rmSync(clientOutputDir, { force: true, recursive: true });

exportTodoHooksForPlaywright();

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile todoapp_rails through Reflaxe.");
  process.exit(1);
}
compileTodoClient();

for (const file of [
  "app/haxe_gen/models/todo.rb",
  "app/haxe_gen/models/user.rb",
  "app/haxe_gen/models/chat_message.rb",
  "app/haxe_gen/controllers/chat_messages_controller.rb",
  "app/haxe_gen/controllers/todo_index_locals.rb",
  "app/haxe_gen/controllers/todos_controller.rb",
  "app/haxe_gen/migrations/create_chat_messages.rb",
  "app/haxe_gen/migrations/create_todos.rb",
  "app/haxe_gen/migrations/add_devise_to_users.rb",
  "app/haxe_gen/migrations/update_todos.rb",
  "app/haxe_gen/migrations/update_users.rb",
  "app/haxe_gen/views/application_layout_view.rb",
  "app/haxe_gen/views/chat_message_view.rb",
  "app/haxe_gen/views/chat_panel_view.rb",
  "app/haxe_gen/views/app_top_bar_view.rb",
  "app/haxe_gen/views/devise_login_view.rb",
  "app/haxe_gen/views/todo_card_view.rb",
  "app/haxe_gen/views/todo_composer_view.rb",
  "app/haxe_gen/views/todo_dashboard_view.rb",
  "app/haxe_gen/views/todo_form_view.rb",
  "app/haxe_gen/views/todo_index_view.rb",
  "app/haxe_gen/views/todo_list_view.rb",
  "app/haxe_gen/views/todo_summary_view.rb",
  "app/views/controllers/todos/index.html.erb",
  "app/views/controllers/todos/_card.html.erb",
  "app/views/controllers/todos/_app_top_bar.html.erb",
  "app/views/controllers/todos/_chat_panel.html.erb",
  "app/views/controllers/todos/_composer.html.erb",
  "app/views/controllers/todos/_dashboard.html.erb",
  "app/views/controllers/todos/_list.html.erb",
  "app/views/controllers/todos/_summary.html.erb",
  "app/views/controllers/todos/_typed_form.html.erb",
  "app/views/devise/sessions/new.html.erb",
  "app/views/layouts/application.html.erb",
  "config/routes.rb",
  "db/migrate/20260101000000_create_todos.rb",
  "db/migrate/20260101000001_update_todos.rb",
  "db/migrate/20260101000002_update_users.rb",
  "db/migrate/20260101000003_create_chat_messages.rb",
  "db/migrate/20260101000004_add_devise_to_users.rb",
  "test/generated/models/todo_haxe_test.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected todoapp_rails output file missing: ${fullPath}`);
    process.exit(1);
  }
}

const todoRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "todo.rb"), "utf8");
for (const expected of [
  'require "active_record"',
  "module Models",
  "class Todo < ::ApplicationRecord",
  'self.table_name = "todos"',
  "def self.__hx_rails_schema()",
  'table_name: "todos"',
  "timestamps: true",
  "{name: :id, haxe_name: \"id\", ruby_name: \"id\", haxe_type: \"Int\", rails_type: :bigint, nullable: false, default: nil, primary_key: true, index: false, unique: false, db_type: :bigint}",
  "{name: :title, haxe_name: \"title\", ruby_name: \"title\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "{name: :notes, haxe_name: \"notes\", ruby_name: \"notes\", haxe_type: \"String\", rails_type: :text, nullable: false, default: \"\", primary_key: false, index: false, unique: false, db_type: :text}",
  "{name: :is_completed, haxe_name: \"isCompleted\", ruby_name: \"is_completed\", haxe_type: \"Bool\", rails_type: :boolean, nullable: false, default: false, primary_key: false, index: false, unique: false, db_type: nil}",
  "{name: :user_id, haxe_name: \"userId\", ruby_name: \"user_id\", haxe_type: \"Int\", rails_type: :integer, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "def self.typed_column_count()",
  "__hx_rails_schema()[:columns].length",
  'belongs_to :user, optional: false, foreign_key: "user_id", inverse_of: :todos',
  "# haxe column id: Int",
  "# haxe column title: String",
  "# haxe column notes: String",
  "# haxe column is_completed: Bool",
  "# haxe column user_id: Int",
  "validates :title, presence: true",
  "validates :notes, length: {maximum: 500}, allow_blank: true",
  "validates :user_id, numericality: {only_integer: true, greater_than: 0}",
  "before_validation :normalize_title",
  "def normalize_title()",
  "def self.incomplete()",
  "Models::Todo.where(is_completed: false)",
]) {
  if (!todoRuby.includes(expected)) {
    console.error(`todoapp_rails model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const userRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "user.rb"), "utf8");
for (const expected of [
  'require "active_record"',
  "module Models",
  "class User < ::ApplicationRecord",
  'self.table_name = "users"',
  "def self.__hx_rails_schema()",
  'table_name: "users"',
  "timestamps: true",
  "{name: :id, haxe_name: \"id\", ruby_name: \"id\", haxe_type: \"Int\", rails_type: :bigint, nullable: false, default: nil, primary_key: true, index: false, unique: false, db_type: :bigint}",
  "{name: :name, haxe_name: \"name\", ruby_name: \"name\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "{name: :email, haxe_name: \"email\", ruby_name: \"email\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "{name: :role, haxe_name: \"role\", ruby_name: \"role\", haxe_type: \"String\", rails_type: :string, nullable: false, default: \"member\", primary_key: false, index: true, unique: false, db_type: nil}",
  "has_many :todos, dependent: :destroy, inverse_of: :user",
  "has_many :chat_messages, dependent: :destroy, inverse_of: :user",
  "# haxe column id: Int",
  "# haxe column name: String",
  "# haxe column email: String",
  "# haxe column role: String",
  "validates :name, presence: true, length: {minimum: 2}",
  'validates :name, exclusion: {within: ["admin", "root", "system"]}',
  "validates :email, presence: true, uniqueness: true, format: {with: /^[^@]+@[^@]+$/}",
  'validates :role, inclusion: {within: ["member", "admin", "maintainer", "guest"]}',
  "def role_label()",
  "def initials()",
  "trimmed__hx0[0, 1].upcase()",
]) {
  if (!userRuby.includes(expected)) {
    console.error(`todoapp_rails user model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const chatMessageRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "chat_message.rb"), "utf8");
for (const expected of [
  'require "active_record"',
  "module Models",
  "class ChatMessage < ::ApplicationRecord",
  'self.table_name = "chat_messages"',
  "def self.__hx_rails_schema()",
  'table_name: "chat_messages"',
  "{name: :body, haxe_name: \"body\", ruby_name: \"body\", haxe_type: \"String\", rails_type: :text, nullable: false, default: nil, primary_key: false, index: false, unique: false, db_type: :text}",
  "{name: :user_id, haxe_name: \"userId\", ruby_name: \"user_id\", haxe_type: \"Int\", rails_type: :integer, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  'belongs_to :user, optional: false, foreign_key: "user_id", inverse_of: :chat_messages',
  "# haxe column body: String",
  "# haxe column user_id: Int",
  "validates :body, presence: true",
  "before_validation :normalize_body",
  "def normalize_body()",
  "def self.latest()",
  "Models::ChatMessage.includes(:user).order(id: :desc).limit(6)",
]) {
  if (!chatMessageRuby.includes(expected)) {
    console.error(`todoapp_rails chat message model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const haxeAuthoredTestRuby = readFileSync(join(outputDir, "test", "generated", "models", "todo_haxe_test.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsTest.",
  'require "test_helper"',
  "class TodoHaxeTest < ActiveSupport::TestCase",
  'test "typed incomplete scope returns typed titles" do',
  'user__hx0 = Models::User.create(name: "haxe test owner", email: "haxe-test-owner@example.test", role: "admin", password: "password123", password_confirmation: "password123")',
  'Models::Todo.create(title: "ship haxe tests", notes: "generated Minitest", is_completed: false, user_id: user__hx0.id)',
  'Models::Todo.create(title: "hide completed work", notes: "done", is_completed: true, user_id: user__hx0.id)',
  'assert_equal(["ship haxe tests"], Models::Todo.incomplete().pluck(:title))',
]) {
  if (!haxeAuthoredTestRuby.includes(expected)) {
    console.error(`todoapp_rails Haxe-authored test output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const haxeRequestTestRuby = readFileSync(join(outputDir, "test", "generated", "controllers", "todos_haxe_request_test.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsTest.",
  'require "test_helper"',
  "class TodosHaxeRequestTest < ActionDispatch::IntegrationTest",
  "include Devise::Test::IntegrationHelpers",
  'test "signed-in users can view their board" do',
  'test "create accepts typed route and request params" do',
  "get(self.todos_path())",
  "assert_response(:ok)",
  "assert_no_difference(-> { Models::Todo.count() }) do",
  "assert_difference(-> { Models::Todo.count() }, 1) { post(self.todos_path(), params:",
  'post(self.todos_path(), params: {"todo" => {title: "from haxe request", notes: "typed request params"}})',
  "assert_redirected_to(self.todos_path())",
  'assert_equal(["from haxe request"], Models::Todo.where(user_id:',
]) {
  if (!haxeRequestTestRuby.includes(expected)) {
    console.error(`todoapp_rails Haxe-authored request test output missing expected line: ${expected}`);
    process.exit(1);
  }
}
for (const expected of [
  /sign_in\(:user,\s*user__hx\d+\)/,
  /sign_out\(:user\)/,
  /Models::User.create\(name: "Haxe Request User", email: "request-viewer@example.test", role: "member", password: "password123", password_confirmation: "password123"\)/,
  /Models::User.create\(name: "Haxe Request User", email: "request-creator@example.test", role: "member", password: "password123", password_confirmation: "password123"\)/,
]) {
  if (!expected.test(haxeRequestTestRuby)) {
    console.error(`todoapp_rails Haxe-authored request test output missing expected pattern: ${expected}`);
    process.exit(1);
  }
}

const generatedRoutes = readFileSync(join(outputDir, "config", "routes.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsRoutes.",
  "# Source: routes.AppRoutes",
  "Rails.application.routes.draw do",
  'devise_for :users, class_name: "Models::User", only: [:sessions]',
  'root "controllers/todos#index"',
  'resources :todos, controller: "controllers/todos", only: [:index, :create]',
  'resources :chat_messages, controller: "controllers/chat_messages", only: [:index, :create]',
  'get "completed", to: "controllers/todos#completed"',
  'patch "complete", to: "controllers/todos#complete"',
  'resources :users, controller: "controllers/users", only: [:index, :create, :update, :destroy]',
  'post "guest", to: "controllers/sessions#create_guest", as: :guest_sign_in',
  'get "reports(/:year)", to: "controllers/todos#optional_report", as: :optional_report',
  'get "files/*path", to: "controllers/todos#file", as: :file',
]) {
  if (!generatedRoutes.includes(expected)) {
    console.error(`todoapp_rails generated routes missing expected line: ${expected}`);
    process.exit(1);
  }
}

const railsOwnedRouteFixture = readFileSync(join(exampleDir, "rails", "config", "routes_rails_owned.rb"), "utf8");
for (const expected of [
  "Rails-owned route fixture.",
  'get "/rails-owned-health"',
  'as: :legacy_health',
  'mount ActionCable.server => "/cable"',
]) {
  if (!railsOwnedRouteFixture.includes(expected)) {
    console.error(`todoapp_rails Rails-owned route fixture missing expected line: ${expected}`);
    process.exit(1);
  }
}

const committedRoutesExtern = readFileSync(join(exampleDir, "src_haxe", "routes", "Routes.hx"), "utf8");
for (const expected of [
  '@:native("users_path")',
  '@:native("chat_messages_path")',
  "public static function chatMessagesPath():String;",
  "public static function usersPath():String;",
  '@:native("user_path")',
  "public static function userPath(id:RouteParam):String;",
  '@:native("completed_todos_path")',
  "public static function completedTodosPath():String;",
  '@:native("complete_todo_path")',
  "public static function completeTodoPath(id:RouteParam):String;",
  '@:native("optional_report_path")',
  "public static function optionalReportPath():String;",
  '@:native("file_path")',
  "public static function filePath(path:RouteParam):String;",
  '@:native("new_user_session_path")',
  "public static function newUserSessionPath():String;",
  '@:native("destroy_user_session_path")',
  "public static function destroyUserSessionPath():String;",
  '@:native("guest_sign_in_path")',
  "public static function guestSignInPath():String;",
  '@:native("legacy_health_path")',
  "public static function legacyHealthPath():String;",
]) {
  if (!committedRoutesExtern.includes(expected)) {
    console.error(`todoapp_rails route extern missing typed Rails-owned route helper: ${expected}`);
    process.exit(1);
  }
}

const routeTestSource = readFileSync(join(exampleDir, "rails", "test", "controllers", "routes_test.rb"), "utf8");
for (const expected of [
  "class RoutesTest < ActionDispatch::IntegrationTest",
  "assert_routing({ path: \"/\", method: :get }, { controller: \"controllers/todos\", action: \"index\" })",
  "assert_recognizes({ controller: \"controllers/todos\", action: \"create\" }, { path: \"/todos\", method: :post })",
  "assert_recognizes({ controller: \"controllers/chat_messages\", action: \"create\" }, { path: \"/chat_messages\", method: :post })",
  "assert_recognizes({ controller: \"controllers/todos\", action: \"completed\" }, { path: \"/todos/completed\", method: :get })",
  "assert_recognizes({ controller: \"controllers/todos\", action: \"complete\", id: \"42\" }, { path: \"/todos/42/complete\", method: :patch })",
  "assert_recognizes({ controller: \"controllers/todos\", action: \"optional_report\", year: \"2026\" }, { path: \"/reports/2026\", method: :get })",
  "assert_recognizes({ controller: \"controllers/todos\", action: \"file\", path: \"docs/readme\" }, { path: \"/files/docs/readme\", method: :get })",
  "assert_equal \"/rails-owned-health\", legacy_health_path",
  "get legacy_health_path",
  "Routes.legacyHealthPath()",
]) {
  if (!routeTestSource.includes(expected)) {
    console.error(`todoapp_rails route runtime test source missing expected content: ${expected}`);
    process.exit(1);
  }
}

const controllerRuby = readFileSync(join(outputDir, "app", "haxe_gen", "controllers", "todos_controller.rb"), "utf8");
for (const expected of [
  /require "action_controller\/railtie"/,
  /module Controllers/,
  /class TodosController < ActionController::Base/,
  /todos__hx\d+ = Models::Todo\.where\(is_completed: false, user_id: current_user__hx\d+\.id\)\.includes\(:user\)\.order\(title: :asc\)\.limit\(10\)\.to_a\(\)/,
  /users__hx\d+ = Models::User\.order\(name: :asc\)\.to_a\(\)/,
  /chat_messages__hx\d+ = Models::ChatMessage\.latest\(\)\.to_a\(\)/,
  /before_action :authenticate_user!/,
  /current_user__hx\d+ = current_user\(\)/,
  /self\.render\(template: "controllers\/todos\/index", locals: \{todos: todos__hx\d+, users: users__hx\d+, chat_messages: chat_messages__hx\d+, todo_count: todos__hx\d+\.length, typed_column_count: Models::Todo\.typed_column_count\(\), current_user: current_user__hx\d+\}, layout: "application"\)/,
  /attrs__hx\d+ = self\.params\(\)\.require\("todo"\)\.permit\(\[:title, :notes\]\)/,
  /attrs__hx\d+ = attrs__hx\d+\.merge\(user_id: current_user__hx\d+\.id\)/,
  /todo__hx\d+ = Models::Todo\.create\(attrs__hx\d+\)/,
  /self\.respond_to\(\) do \|format__hx\d+\|/,
  /format__hx\d+\.turbo_stream\(\) \{ gthis__hx\d+\.render\(turbo_stream: turbo_stream\.replace\("railshx-todo-list", partial: "controllers\/todos\/list", locals: \{todos: Models::Todo\.where\(is_completed: false, user_id: current_user__hx\d+\.id\)\.includes\(:user\)\.order\(title: :asc\)\.limit\(10\)\.to_a\(\)\}\)\) \}/,
  /format__hx\d+\.html\(\) \{ gthis__hx\d+\.redirect_to\(self\.todos_path\(\), status: :see_other\) \}/,
]) {
  if (!expected.test(controllerRuby)) {
    console.error(`todoapp_rails controller output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const chatMessagesControllerRuby = readFileSync(join(outputDir, "app", "haxe_gen", "controllers", "chat_messages_controller.rb"), "utf8");
for (const expected of [
  /class ChatMessagesController < ActionController::Base/,
  /before_action :authenticate_user!/,
  /def index\(\)/,
  /attrs__hx\d+ = self\.params\(\)\.require\("chat_message"\)\.permit\(\[:body\]\)/,
  /attrs__hx\d+ = attrs__hx\d+\.merge\(user_id: current_user__hx\d+\.id\)/,
  /message__hx\d+ = Models::ChatMessage\.create\(attrs__hx\d+\)/,
  /Turbo::StreamsChannel\.broadcast_prepend_to\("todoapp:chat", target: "railshx-chat-list", partial: "controllers\/todos\/chat_message", locals: \{message: message__hx\d+\}\)/,
  /format__hx\d+\.turbo_stream\(\) \{ gthis__hx\d+\.head\(:no_content\) \}/,
  /format__hx\d+\.html\(\) \{ gthis__hx\d+\.redirect_to\(self\.todos_path\(\), status: :see_other\) \}/,
]) {
  if (!expected.test(chatMessagesControllerRuby)) {
    console.error(`todoapp_rails chat messages controller output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const sessionsControllerRuby = readFileSync(join(outputDir, "app", "haxe_gen", "controllers", "sessions_controller.rb"), "utf8");
for (const expected of [
  /class SessionsController < ActionController::Base/,
  /def create_guest\(\)/,
  /guest__hx\d+ = Models::User\.find_by\(email: "guest@example\.test"\)/,
  /sign_in\(:user, guest__hx\d+\)/,
  /self\.flash\(\)\[:notice\] = "Signed in as the guest workspace"/,
  /self\.redirect_to\(self\.todos_path\(\), status: :see_other\)/,
]) {
  if (!expected.test(sessionsControllerRuby)) {
    console.error(`todoapp_rails sessions controller output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const usersControllerRuby = readFileSync(join(outputDir, "app", "haxe_gen", "controllers", "users_controller.rb"), "utf8");
for (const expected of [
  /class UsersController < ActionController::Base/,
  /before_action :authenticate_user!/,
  /current_user__hx\d+ = self\.require_admin\(\)/,
  /users__hx\d+ = Models::User\.order\(name: :asc\)\.to_a\(\)/,
  /self\.render\(template: "controllers\/users\/index", locals: \{users: users__hx\d+, current_user: current_user__hx\d+\}, layout: "application"\)/,
  /def create\(\)/,
  /self\.params\(\)\.require\("user"\)\.permit\(\[:name, :email, :role, :password, :password_confirmation\]\)/,
  /Models::User\.create\(attrs__hx\d+\)/,
  /self\.flash\(\)\[:notice\] = "User created"/,
  /def update\(\)/,
  /Models::User\.find\(self\.param_id\(\)\)/,
  /user__hx\d+\.update\(attrs__hx\d+\)/,
  /def destroy\(\)/,
  /user__hx\d+\.destroy\(\)/,
  /self\.flash\(\)\[:alert\] = "Admin access is required for user management"/,
]) {
  if (!expected.test(usersControllerRuby)) {
    console.error(`todoapp_rails users controller output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const migrationClassRuby = readFileSync(join(outputDir, "app", "haxe_gen", "migrations", "create_todos.rb"), "utf8");
for (const expected of [
  "module Migrations",
  "class CreateTodos",
  'def self.__hx_name()',
  '"migrations.CreateTodos"',
]) {
  if (!migrationClassRuby.includes(expected)) {
    console.error(`todoapp_rails migration marker output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const updateMigrationClassRuby = readFileSync(join(outputDir, "app", "haxe_gen", "migrations", "update_todos.rb"), "utf8");
for (const expected of [
  "module Migrations",
  "class UpdateTodos",
  'def self.__hx_name()',
  '"migrations.UpdateTodos"',
]) {
  if (!updateMigrationClassRuby.includes(expected)) {
    console.error(`todoapp_rails update migration marker output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const chatMigrationClassRuby = readFileSync(join(outputDir, "app", "haxe_gen", "migrations", "create_chat_messages.rb"), "utf8");
for (const expected of [
  "module Migrations",
  "class CreateChatMessages",
  'def self.__hx_name()',
  '"migrations.CreateChatMessages"',
]) {
  if (!chatMigrationClassRuby.includes(expected)) {
    console.error(`todoapp_rails chat migration marker output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const updateUsersMigrationClassRuby = readFileSync(join(outputDir, "app", "haxe_gen", "migrations", "update_users.rb"), "utf8");
for (const expected of [
  "module Migrations",
  "class UpdateUsers",
  'def self.__hx_name()',
  '"migrations.UpdateUsers"',
]) {
  if (!updateUsersMigrationClassRuby.includes(expected)) {
    console.error(`todoapp_rails user migration marker output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const deviseMigrationClassRuby = readFileSync(join(outputDir, "app", "haxe_gen", "migrations", "add_devise_to_users.rb"), "utf8");
for (const expected of [
  "module Migrations",
  "class AddDeviseToUsers",
  'def self.__hx_name()',
  '"migrations.AddDeviseToUsers"',
]) {
  if (!deviseMigrationClassRuby.includes(expected)) {
    console.error(`todoapp_rails Devise migration marker output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const migrationRuby = readFileSync(join(outputDir, "db", "migrate", "20260101000000_create_todos.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsMigration.",
  "class CreateTodos < ActiveRecord::Migration[7.1]",
  "create_table :users do |t|",
  "t.string :name, null: false",
  "t.index [:name]",
  "create_table :todos do |t|",
  "t.string :title, null: false",
  't.text :notes, null: false, default: ""',
  "t.boolean :is_completed, null: false, default: false",
  "t.references :user, null: false, foreign_key: true",
  "t.index [:title]",
]) {
  if (!migrationRuby.includes(expected)) {
    console.error(`todoapp_rails generated migration missing expected line: ${expected}`);
    process.exit(1);
  }
}

const updateMigrationRuby = readFileSync(join(outputDir, "db", "migrate", "20260101000001_update_todos.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsMigration.",
  "class UpdateTodos < ActiveRecord::Migration[7.1]",
  "change_column :todos, :title, :string, null: false",
  "reversible do |dir|",
  "dir.up do",
  'add_foreign_key :todos, :users, column: :user_id, name: "fk_todos_users", on_delete: :cascade',
  "dir.down do",
  'remove_foreign_key :todos, name: "fk_todos_users"',
  "change_column :todos, :title, :string",
  "add_column :todos, :priority, :integer, null: false, default: 0",
  'add_index :todos, :priority, name: "index_todos_on_priority"',
  'add_index :todos, [:user_id, :priority], name: "index_todos_on_user_id_and_priority"',
  'remove_index :todos, name: "index_todos_on_user_id_and_priority"',
  "execute \"UPDATE todos SET priority = 0 WHERE priority IS NULL\"",
  "execute \"UPDATE todos SET priority = NULL WHERE priority = 0\"",
]) {
  if (!updateMigrationRuby.includes(expected)) {
    console.error(`todoapp_rails generated update migration missing expected line: ${expected}`);
    process.exit(1);
  }
}

const chatMigrationRuby = readFileSync(join(outputDir, "db", "migrate", "20260101000003_create_chat_messages.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsMigration.",
  "class CreateChatMessages < ActiveRecord::Migration[7.1]",
  "create_table :chat_messages do |t|",
  "t.text :body, null: false",
  "t.references :user, null: false, foreign_key: true",
  "t.index [:user_id, :id]",
]) {
  if (!chatMigrationRuby.includes(expected)) {
    console.error(`todoapp_rails generated chat migration missing expected line: ${expected}`);
    process.exit(1);
  }
}

const updateUsersMigrationRuby = readFileSync(join(outputDir, "db", "migrate", "20260101000002_update_users.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsMigration.",
  "class UpdateUsers < ActiveRecord::Migration[7.1]",
  'add_column :users, :email, :string, null: false, default: "owner@example.test"',
  'add_column :users, :role, :string, null: false, default: "member"',
  "add_index :users, :email, unique: true",
  "add_index :users, :role",
]) {
  if (!updateUsersMigrationRuby.includes(expected)) {
    console.error(`todoapp_rails generated user migration missing expected line: ${expected}`);
    process.exit(1);
  }
}

const deviseMigrationRuby = readFileSync(join(outputDir, "db", "migrate", "20260101000004_add_devise_to_users.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsMigration.",
  "class AddDeviseToUsers < ActiveRecord::Migration[7.1]",
  'add_column :users, :encrypted_password, :string, null: false, default: ""',
]) {
  if (!deviseMigrationRuby.includes(expected)) {
    console.error(`todoapp_rails generated Devise migration missing expected line: ${expected}`);
    process.exit(1);
  }
}

const readme = readFileSync(join(exampleDir, "README.md"), "utf8");
for (const expected of [
  "RailsHx Todo App",
  "self.__hx_rails_schema",
  "ParamsMacro.requirePermit",
  "ViewMacro.renderTemplate",
  "Haxe-authored Rails migration",
  "<text_area>",
  "Haxe-authored JavaScript",
  "models/ChatMessage.hx",
  "views/ChatPanelView.hx",
  "views/ChatMessageView.hx",
]) {
  if (!readme.includes(expected)) {
    console.error(`todoapp_rails README missing expected line: ${expected}`);
    process.exit(1);
  }
}

const layoutSource = readFileSync(join(exampleDir, "views", "ApplicationLayoutView.hx"), "utf8");
for (const expected of [
  '@:railsTemplate("layouts/application")',
  '@:railsTemplateAst("render")',
  "<doctype_html />",
  "<csrf_meta_tags />",
  '<yield_content name="head" />',
  '<stylesheet_link_tag name="application" data-turbo-track="reload" />',
  "<javascript_importmap_tags />",
  "<rails_yield />",
]) {
  if (!layoutSource.includes(expected)) {
    console.error(`todoapp_rails layout source is missing expected HHX content: ${expected}`);
    process.exit(1);
  }
}
for (const forbidden of ["public static var body", "public static var erb", "public static var template", "<%"]) {
  if (layoutSource.includes(forbidden)) {
    console.error(`todoapp_rails layout source must stay HHX-first and cannot contain: ${forbidden}`);
    process.exit(1);
  }
}

const indexSource = readFileSync(join(exampleDir, "views", "TodoIndexView.hx"), "utf8");
for (const expected of [
  '@:railsTemplateAst("render")',
  "return <>",
  '<content_for name=${TodoHooks.headSlot}>',
  '<meta name=${TodoHooks.templateMetaName} content=${TodoHooks.templateMetaContent} />',
  '<main class=${TodoHooks.shellClass}>',
  '<partial template=${(Template.of(TodoComposerView)',
  '<partial template=${(Template.of(TodoListView)',
  '<partial template=${(Template.of(ChatPanelView)',
  '<partial template=${(Template.of(TodoDashboardView)',
]) {
  if (!indexSource.includes(expected)) {
    console.error(`todoapp_rails index source is missing expected HHX content: ${expected}`);
    process.exit(1);
  }
}
for (const forbidden of [
  "@:railsAllowRawErb",
  "public static var body",
  "public static var erb",
  "public static var template",
  "<%",
  "<%=",
]) {
  if (indexSource.includes(forbidden)) {
    console.error(`todoapp_rails index source must stay HHX-first and cannot contain: ${forbidden}`);
    process.exit(1);
  }
}

const routesSource = readFileSync(join(exampleDir, "src_haxe", "routes", "AppRoutes.hx"), "utf8");
for (const expected of [
  "@:railsRoutes",
  "static final routes = {",
  "DeviseRoutes.deviseFor(UserAuth.scope, {only: [Sessions]});",
  "root(to(TodosController, index));",
  "resources(Todo, TodosController, {only: [index, create]}, {",
  "resources(ChatMessage, ChatMessagesController, {only: [index, create]});",
  "resources(User, UsersController, {only: [index, create, update, destroy]});",
  "collection({",
  'get("completed", to(TodosController, completed));',
  "member({",
  'patch("complete", to(TodosController, complete));',
  'post("guest", to(SessionsController, createGuest), {asName: routeName("guest_sign_in")});',
  'get("reports(/:year)", to(TodosController, optionalReport), {asName: routeName("optional_report")});',
  'get("files/*path", to(TodosController, file), {asName: routeName("file")});',
]) {
  if (!routesSource.includes(expected)) {
    console.error(`todoapp_rails route source is missing expected Haxe-owned route content: ${expected}`);
    process.exit(1);
  }
}
for (const forbidden of ['"controllers/todos#index"', 'writeFile("config/routes.rb"']) {
  if (routesSource.includes(forbidden)) {
    console.error(`todoapp_rails Haxe route source should use typed route declarations, not raw route output: ${forbidden}`);
    process.exit(1);
  }
}

const hooksSource = readFileSync(join(exampleDir, "shared", "TodoHooks.hx"), "utf8");
for (const expected of [
  "class TodoHooks",
  "abstract CssClass(String)",
  'public static inline var formClass:CssClass = "todo-form";',
  'public static inline var sessionFormClass:CssClass = "session-form";',
  'public static inline var sessionFooterClass:CssClass = "session-footer";',
  'public static inline var chatFormClass:CssClass = "chat-form";',
  'public static inline var chatPanelId:DomId = "railshx-chat-panel";',
  'public static inline var chatListId:DomId = "railshx-chat-list";',
  'public static inline var chatMessageKeyAttr:DataAttr = "data-railshx-chat-message-key";',
  'public static inline var openWorkId:DomId = "open-work";',
  'public static inline var boundAttr:DataAttr = "data-railshx-bound";',
  'public static inline var sessionAttr:DataAttr = "data-railshx-session";',
  "public static inline function classSelector",
  "public static inline function idSelector",
  "public static inline function attrEqualsSelector",
]) {
  if (!hooksSource.includes(expected)) {
    console.error(`todoapp_rails hook source missing expected typed hook content: ${expected}`);
    process.exit(1);
  }
}

const hookExportSource = readFileSync(join(exampleDir, "tools", "ExportTodoHooks.hx"), "utf8");
for (const expected of [
  "import shared.TodoHooks;",
  "examples/todoapp_rails/e2e/todo_hooks.ts",
  "TodoHooks.classSelector(TodoHooks.formClass)",
  "TodoHooks.classSelector(TodoHooks.chatFormClass)",
]) {
  if (!hookExportSource.includes(expected)) {
    console.error(`todoapp_rails hook exporter missing expected content: ${expected}`);
    process.exit(1);
  }
}

const hookSpecSource = readFileSync(join(exampleDir, "e2e", "todoapp.spec.ts"), "utf8");
for (const expected of [
  "import { hooks } from './todo_hooks'",
  "hooks.selectors.form",
  "hooks.selectors.sessionForms",
  "hooks.selectors.chatForms",
  "hooks.selectors.chatPanel",
  "turbo-cable-stream-source[connected]",
  "hooks.attrs.bound",
  "hooks.selectors.openWork",
  "lets admins create, update, and remove users through typed RailsHx CRUD",
  "Admin-only RailsHx user management",
  "await loginAsOwner(page)",
]) {
  if (!hookSpecSource.includes(expected)) {
    console.error(`todoapp_rails Playwright spec missing generated hook usage: ${expected}`);
    process.exit(1);
  }
}

const hookManifest = readFileSync(join(exampleDir, "e2e", "todo_hooks.ts"), "utf8");
for (const expected of [
  "// Generated by examples/todoapp_rails/tools/ExportTodoHooks.hx.",
  'form: "todo-form"',
  'sessionForm: "session-form"',
  'sessionFooter: "session-footer"',
  'chatForm: "chat-form"',
  'chatPanel: "railshx-chat-panel"',
  'scrollLinks: "[data-railshx-scroll]"',
  'sessionForms: "[data-railshx-session]"',
  'sessionFooter: ".session-footer"',
  'chatForms: ".chat-form"',
  'chatPanel: "#railshx-chat-panel"',
  'openWork: "#open-work"',
]) {
  if (!hookManifest.includes(expected)) {
    console.error(`todoapp_rails generated Playwright hook manifest missing expected content: ${expected}`);
    process.exit(1);
  }
}

const appCss = readFileSync(join(exampleDir, "assets", "stylesheets", "application.css"), "utf8");
for (const expected of [
  ".chat-panel turbo-cable-stream-source",
  ".chat-panel turbo-cable-stream-source::after",
  ".chat-panel turbo-cable-stream-source[connected]::after",
  'content: "live";',
]) {
  if (!appCss.includes(expected)) {
    console.error(`todoapp_rails stylesheet missing native Turbo stream status styling: ${expected}`);
    process.exit(1);
  }
}

const view = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "index.html.erb"), "utf8");
for (const expected of [
  "RailsHx sample",
  "Typed Rails, polished Ruby.",
  "<% content_for :head do %>",
  '<meta name="railshx-template" content="todo-index">',
  "<%= todo_count %>",
  "<%= typed_column_count %>",
  '<%= render partial: "controllers/todos/app_top_bar", locals: {current_user: current_user} %>',
  '<turbo-frame id="railshx-user-frame" class="user-management-frame"></turbo-frame>',
  '<%= render partial: "controllers/todos/composer", locals: {current_user: current_user} %>',
  '<%= render partial: "controllers/todos/list", locals: {todos: todos} %>',
  '<%= render partial: "controllers/todos/chat_panel", locals: {messages: chat_messages, current_user: current_user, users: users} %>',
  "todo-shell",
  '<%= render partial: "controllers/todos/dashboard", locals: {todos: todos, users: users, chat_messages: chat_messages, todo_count: todo_count, typed_column_count: typed_column_count, current_user: current_user} %>',
]) {
  if (!view.includes(expected)) {
    console.error(`todoapp_rails view missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedChatPanel = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_chat_panel.html.erb"), "utf8");
for (const expected of [
  'id="railshx-chat-panel"',
  '<%= turbo_stream_from "todoapp:chat" %>',
  "Typed Turbo room",
  "This is a Rails-native chat slice",
  '<ul id="railshx-chat-list" class="chat-list">',
  "<% messages.each do |message| %>",
  '<%= render partial: "controllers/todos/chat_message", locals: {message: message} %>',
  "<% if messages.length == 0 %>",
  '<%= form_with url: chat_messages_path(), scope: :chat_message, local: true, class: "chat-form", data: {railshx_chat_form: true} do |form| %>',
  '<%= form.label :body, "Add a typed room note" %>',
  '<%= form.text_area :body, placeholder: "Share what changed, what blocked, or what shipped", rows: 3, required: true %>',
  '<%= form.submit "Post note", type: "submit" %>',
]) {
  if (!typedChatPanel.includes(expected)) {
    console.error(`todoapp_rails typed chat panel missing expected content: ${expected}`);
    process.exit(1);
  }
}
if (typedChatPanel.includes("hidden_field :user_id")) {
  console.error("todoapp_rails chat panel must not render a spoofable user_id hidden field.");
  process.exit(1);
}

const typedChatMessage = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_chat_message.html.erb"), "utf8");
for (const expected of [
  '<li class="chat-message" data-railshx-chat-message-key="<%= message.id %>">',
  "<strong>User <%= message.user_id %></strong>",
  "<p><%= message.body %></p>",
]) {
  if (!typedChatMessage.includes(expected)) {
    console.error(`todoapp_rails typed chat message partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const todoappMaterializer = readFileSync(join(root, "scripts", "rails", "todoapp.js"), "utf8");
for (const expected of [
  'pin "@rails/actioncable", to: "actioncable.esm.js"',
  'pin "railshx/todo_client", to: "railshx/todo_client.js"',
  'writeFile("config/cable.yml"',
  "adapter: test",
]) {
  if (!todoappMaterializer.includes(expected)) {
    console.error(`todoapp_rails materializer missing expected ActionCable/client importmap pin: ${expected}`);
    process.exit(1);
  }
}

for (const expected of [
  'import("railshx/todo_client")',
]) {
  if (!todoappMaterializer.includes(expected)) {
    console.error(`todoapp_rails materializer missing expected ActionCable boot content: ${expected}`);
    process.exit(1);
  }
}

for (const stale of [
  'import * as ActionCable from "@rails/actioncable"',
  "window.ActionCable = ActionCable",
  "include ActionCable::TestHelper",
]) {
  if (todoappMaterializer.includes(stale)) {
    console.error(`todoapp_rails materializer still contains non-canonical ActionCable boot content: ${stale}`);
    process.exit(1);
  }
}

const layoutView = readFileSync(join(outputDir, "app", "views", "layouts", "application.html.erb"), "utf8");
for (const expected of [
  "<!DOCTYPE html>",
  "<title>RailsHx Todoapp</title>",
  '<%= csrf_meta_tags %>',
  '<%= csp_meta_tag %>',
  '<%= yield :head %>',
  '<%= stylesheet_link_tag "application", data: {turbo_track: "reload"} %>',
  '<%= javascript_importmap_tags %>',
  '<%= yield %>',
]) {
  if (!layoutView.includes(expected)) {
    console.error(`todoapp_rails layout output missing expected content: ${expected}`);
    process.exit(1);
  }
}
for (const forbidden of ["<% todos ||= [] %>", "<% sample_user = Models::User.order(:id).first %>", "controllers/todos/hero", "controllers/todos/user_switcher"]) {
  if (view.includes(forbidden)) {
    console.error(`todoapp_rails HHX index should not contain raw shell content: ${forbidden}`);
    process.exit(1);
  }
}

const typedPartial = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_summary.html.erb"), "utf8");
for (const expected of [
  "Typed template partial",
  "typed Rails HHX",
  "<%= todos.length %>",
  "<% if todos.length == 0 %>",
  "No typed HHX todos yet.",
  "<% else %>",
  "<% todos.each do |todo| %>",
  "<%= todo.title %>",
  "<%= todo.notes %>",
  "typed-template-card",
]) {
  if (!typedPartial.includes(expected)) {
    console.error(`todoapp_rails typed template partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedCard = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_card.html.erb"), "utf8");
for (const expected of [
  '<span class="eyebrow"><%= eyebrow %></span>',
  "<h2><%= title %></h2>",
  "<%= body %>",
  "typed-dashboard",
]) {
  if (!typedCard.includes(expected)) {
    console.error(`todoapp_rails typed card component missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedDashboard = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_dashboard.html.erb"), "utf8");
for (const expected of [
  "<% railshx_component_body = capture do %>",
  '<%= link_to "#open-work", class: "typed-route-link", data: {railshx_scroll: true} do %>',
  '<%= link_to legacy_health_path(), class: "typed-route-link rails-owned-route-link" do %>',
  "Rails-owned route, typed in Haxe",
  '<span><%= (if todos.length > 0 then "Jump to open work" else "Jump to the empty state" end) %></span>',
  '<span class="typed-route-count"><%= todos.length %></span>',
  '<% end %>',
  '<%= render partial: "controllers/todos/summary", locals: {todos: todos} %>',
  '<%= render partial: "controllers/todos/card", locals: {eyebrow: "Composed typed component", title: "One typed component, reused by Rails.", body: railshx_component_body} %>',
]) {
  if (!typedDashboard.includes(expected)) {
    console.error(`todoapp_rails typed dashboard partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedComposer = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_composer.html.erb"), "utf8");
for (const expected of [
  '<%= render partial: "controllers/todos/typed_form", locals: {current_user_name: current_user.name} %>',
]) {
  if (!typedComposer.includes(expected)) {
    console.error(`todoapp_rails typed composer partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedList = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_list.html.erb"), "utf8");
for (const expected of [
  '<div id="railshx-todo-list" class="todo-list-frame">',
  "<% if todos.length > 0 %>",
  '<ul class="todo-list">',
  "<% todos.each do |todo| %>",
  '<li class="todo-item">',
  "<%= todo.title %>",
  "<%= todo.notes %>",
  "<% else %>",
  "No open tasks. Serene, but suspicious.",
]) {
  if (!typedList.includes(expected)) {
    console.error(`todoapp_rails typed list partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedForm = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_typed_form.html.erb"), "utf8");
for (const expected of [
  '<%= form_with url: todos_path(), scope: :todo, local: true, class: "todo-form" do |form| %>',
  '<p class="form-owner-note">New tasks will be assigned to <%= current_user_name %>.</p>',
  '<%= form.label :title, "What should ship next?" %>',
  '<%= form.search_field :title, placeholder: "Write the HHX form DSL", required: true %>',
  '<% form.object.errors[:title].each do |message| %><p class="field-error" aria-live="polite"><%= message %></p><% end %>',
  '<%= form.label :notes, "Why does it matter?" %>',
  '<%= form.text_area :notes, placeholder: "Add a short implementation note", rows: 3 %>',
  '<% form.object.errors[:notes].each do |message| %><p class="field-error"><%= message %></p><% end %>',
  '<%= form.submit "Add task", type: "submit" %>',
]) {
  if (!typedForm.includes(expected)) {
    console.error(`todoapp_rails typed form partial missing expected content: ${expected}`);
    process.exit(1);
  }
}
if (typedForm.includes("hidden_field :user_id")) {
  console.error("todoapp_rails typed form must not render a spoofable user_id hidden field.");
  process.exit(1);
}

const typedAppTopBar = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_app_top_bar.html.erb"), "utf8");
for (const expected of [
  '<header class="app-topbar" aria-label="Todoapp session">',
  "RailsHx Todo",
  "Devise session active",
  '<% if current_user.can_manage_users() %>',
  '<%= link_to users_path(), class: "typed-route-link topbar-link", data: {turbo_frame: "railshx-user-frame"} do %>',
  '<%= link_to "#open-work", class: "typed-route-link topbar-link", data: {railshx_scroll: true} do %>',
  '<span class="avatar"><%= current_user.initials() %></span>',
  '<strong><%= current_user.name %></strong>',
  '<em><%= current_user.role_label() %> · <%= current_user.email %></em>',
  '<%= button_to "Log out", destroy_user_session_path(), method: "delete", class: "session-clear-form topbar-logout", data: {railshx_session: true} %>',
]) {
  if (!typedAppTopBar.includes(expected)) {
    console.error(`todoapp_rails typed app top bar partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedDeviseLogin = readFileSync(join(outputDir, "app", "views", "devise", "sessions", "new.html.erb"), "utf8");
for (const expected of [
  '<main class="login-shell">',
  "Sign in to the typed Rails board.",
  "Devise owns Warden, password verification, sessions, and redirects.",
  "Seeded demo",
  "owner@example.test",
  "password123",
  '<%= form_with url: user_session_path(), scope: :user, local: true, class: "login-form", data: {railshx_session: true} do |form| %>',
  '<%= form.email_field :email, autocomplete: "email", placeholder: "owner@example.test", autofocus: true, required: true %>',
  '<%= form.password_field :password, autocomplete: "current-password", placeholder: "password123", required: true %>',
  '<%= button_to "Continue as guest", guest_sign_in_path(), method: "post", class: "auth-guest-form", data: {railshx_session: true} %>',
]) {
  if (!typedDeviseLogin.includes(expected)) {
    console.error(`todoapp_rails typed Devise login view missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedUsersPage = readFileSync(join(outputDir, "app", "views", "controllers", "users", "index.html.erb"), "utf8");
for (const expected of [
  "Admin-only RailsHx user management",
  "Typed users, ordinary Rails CRUD.",
  '<turbo-frame id="railshx-user-frame" class="user-management-frame">',
  '<%= link_to "Back to todo board", todos_path(), class: "typed-route-link", data: {turbo_frame: "_top"} %>',
  '<%= form_with url: users_path(), scope: :user, local: true, class: "user-create-form" do |form| %>',
  '<%= form.select :role, [["Member", "member"], ["Admin", "admin"]], {selected: "member"}, {required: true} %>',
  '<%= form.password_field :password, placeholder: "password123", required: true %>',
  '<%= form_with url: user_path(user.id), scope: :user, method: "patch", local: true, class: "user-card-form" do |form| %>',
  '<%= form.select :role, [["Member", "member"], ["Admin", "admin"]], {selected: user.role}, {id: "user_" + user.id.to_s + "_role", required: true} %>',
  '<%= form_with url: user_path(user.id), scope: :user, method: "delete", local: true, class: "user-delete-form" do |form| %>',
  '<%= form.submit "Remove user", type: "submit" %>',
  "<% users.each do |user| %>",
  '<span class="avatar"><%= user.initials() %></span>',
  "<h2><%= user.name %></h2>",
  "<p><%= user.email %></p>",
  '<span class="role-pill"><%= user.role_label() %></span>',
]) {
  if (!typedUsersPage.includes(expected)) {
    console.error(`todoapp_rails typed users page missing expected content: ${expected}`);
    process.exit(1);
  }
}

expectInvalidTemplateLocalsFailure();
expectRawErbRequiresOptInFailure();
expectTypedTemplateAstFieldFailure();
expectTypedPartialLocalsFailure();
expectCheckedAttrHelpersOutput();
expectCheckedAttrHelpersFailure();
expectButtonTagTypeFailure();
expectSubmitTagTypeFailure();
expectTextFieldTagTypeFailure();
expectSearchFieldTagTypeFailure();
expectEmailFieldTagTypeFailure();
expectTelephoneFieldTagTypeFailure();
expectUrlFieldTagTypeFailure();
expectNumberFieldTagTypeFailure();
expectRangeFieldTagTypeFailure();
expectColorFieldTagTypeFailure();
expectDateFieldTagTypeFailure();
expectTimeFieldTagTypeFailure();
expectDatetimeFieldTagTypeFailure();
expectMonthFieldTagTypeFailure();
expectWeekFieldTagTypeFailure();
expectPasswordFieldTagTypeFailure();
expectHiddenFieldTagTypeFailure();
expectFileFieldTagTypeFailure();
expectTextAreaTagTypeFailure();
expectCheckBoxTagTypeFailure();
expectRadioButtonTagTypeFailure();
expectFormSelectOptionTypeFailure();
expectFormSearchFieldTypeFailure();
expectFormEmailFieldTypeFailure();
expectPictureTagTypeFailure();
expectFaviconLinkTagTypeFailure();
expectPreloadLinkTagTypeFailure();
expectJavascriptIncludeTagTypeFailure();
expectJavascriptTagTypeFailure();
expectAutoDiscoveryLinkTagTypeFailure();
expectAudioTagTypeFailure();
expectVideoTagTypeFailure();
expectPhoneToTypeFailure();
expectSmsToTypeFailure();
expectExcerptTypeFailure();
expectHighlightTypeFailure();
expectWordWrapTypeFailure();
expectSanitizeTypeFailure();
expectSanitizeCssTypeFailure();
expectStripTagsTypeFailure();
expectStripLinksTypeFailure();
expectToSentenceTypeFailure();
expectEscapeOnceTypeFailure();
expectCdataSectionTypeFailure();
expectSafeJoinTypeFailure();
expectTokenListTypeFailure();
expectClassNamesTypeFailure();
expectCycleTypeFailure();
expectCurrentCycleTypeFailure();
expectResetCycleTypeFailure();
expectTimeAgoInWordsTypeFailure();
expectDistanceOfTimeInWordsTypeFailure();
expectTimeTagTypeFailure();
expectNumberToPhoneTypeFailure();
expectNumberToHumanSizeTypeFailure();
expectNumberWithPrecisionTypeFailure();
expectNumberWithDelimiterTypeFailure();
expectTypedRouteHelperFailure();
expectTypedRouteParamFailure();
expectTypedFormFieldRequiresFormFailure();
expectTypedSlotContentRequiresComponentFailure();
expectTemplateOfRequiresRailsTemplateFailure();
expectUnsafeRailsTemplatePathFailure();
expectBackslashRailsTemplatePathFailure();
expectRawLayoutStringFailure();
expectUnknownTypedFormFieldFailure();
expectUnknownStrongParamsFieldFailure();
expectMixedModelStrongParamsFailure();
expectUnknownRequestParamsFieldFailure();
expectMigrationDuplicateTableFailure();
expectMigrationDuplicateFileFailure();
expectMigrationNonModelFailure();
expectMigrationBadTimestampFailure();
expectMigrationUnknownOptionFailure();
expectMigrationBadOperationFailure();
expectMigrationUnsafeSqlFailure();
expectMigrationDuplicateTimestampFailure();
expectMigrationForeignKeyOrderFailure();
expectMigrationIrreversibleOperationFailure();
expectMigrationUnknownTableFailure();
expectMigrationUnknownColumnFailure();
expectMigrationUnsafeIndexNameFailure();
expectMigrationUnsafeForeignKeyNameFailure();
expectMigrationUnsafeCheckConstraintNameFailure();
expectMigrationExternalTableAllowed();
expectMigrationUnsafeExternalTableFailure();
expectMigrationDropTableReversibleOutput();
expectMigrationSnapshotOperationsOutput();
expectMigrationHistoricalAddColumnAllowed();
expectMigrationDuplicateAddColumnFailure();

function compileWithFirstAvailableReflaxe() {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${outputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      join(exampleDir, "src_haxe"),
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "Main",
    ], { allowFailure: true });
    if (result.status === 0) {
      return result;
    }
  }
  return null;
}

function exportTodoHooksForPlaywright() {
  run("haxe", [
    "-cp",
    exampleDir,
    "-main",
    "tools.ExportTodoHooks",
    "--interp",
  ]);
}

function expectInvalidMigrationCompile(sourceDir, invalidOutputDir, mainClass, successMessage, expectedDiagnostic) {
  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${invalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      sourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      mainClass,
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error(successMessage);
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes(expectedDiagnostic)) {
      console.error(`Invalid migration failed, but not with the expected diagnostic: ${expectedDiagnostic}`);
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid migration check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function compileValidMigration(sourceDir, validOutputDir, mainClass) {
  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${validOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      sourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      mainClass,
    ], { allowFailure: true });
    if (result.status === 0) {
      return;
    }
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  if (!sawCandidate) {
    console.error("Unable to run valid migration check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectMigrationDuplicateTableFailure() {
  mkdirSync(join(migrationDuplicateTableSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationDuplicateTableSourceDir, "InvalidDuplicateTableMain.hx"), [
    "import migrations.BadDuplicateTable;",
    "",
    "class InvalidDuplicateTableMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadDuplicateTable> = BadDuplicateTable;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDuplicateTableSourceDir, "migrations", "BadDuplicateTable.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000001\",",
    "\tclassName: \"BadDuplicateTable\",",
    "\tmodels: [\"models.User\", \"models.User\"]",
    "})",
    "class BadDuplicateTable extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationDuplicateTableSourceDir,
    migrationDuplicateTableOutputDir,
    "InvalidDuplicateTableMain",
    "Duplicate-table RailsHx migration compiled successfully.",
    "@:railsMigration cannot create table \"users\" more than once"
  );
}

function expectMigrationDuplicateFileFailure() {
  mkdirSync(join(migrationDuplicateFileSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationDuplicateFileSourceDir, "InvalidDuplicateFileMain.hx"), [
    "import migrations.BadDuplicateFileA;",
    "import migrations.BadDuplicateFileB;",
    "",
    "class InvalidDuplicateFileMain {",
    "\tstatic function main() {",
    "\t\tvar first:Class<BadDuplicateFileA> = BadDuplicateFileA;",
    "\t\tvar second:Class<BadDuplicateFileB> = BadDuplicateFileB;",
    "\t\tSys.println(first != null && second != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDuplicateFileSourceDir, "migrations", "BadDuplicateFileA.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000002\",",
    "\tclassName: \"BadDuplicateFile\",",
    "\tmodels: [\"models.User\"]",
    "})",
    "class BadDuplicateFileA extends Migration {}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDuplicateFileSourceDir, "migrations", "BadDuplicateFileB.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000002\",",
    "\tclassName: \"BadDuplicateFile\",",
    "\tmodels: [\"models.Todo\"]",
    "})",
    "class BadDuplicateFileB extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationDuplicateFileSourceDir,
    migrationDuplicateFileOutputDir,
    "InvalidDuplicateFileMain",
    "Duplicate-file RailsHx migration compiled successfully.",
    "@:railsMigration emits duplicate migration file db/migrate/20260101000002_bad_duplicate_file.rb"
  );
}

function expectMigrationNonModelFailure() {
  mkdirSync(join(migrationNonModelSourceDir, "invalid"), { recursive: true });
  mkdirSync(join(migrationNonModelSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationNonModelSourceDir, "InvalidNonModelMigrationMain.hx"), [
    "import migrations.BadNonModelMigration;",
    "",
    "class InvalidNonModelMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadNonModelMigration> = BadNonModelMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationNonModelSourceDir, "invalid", "Plain.hx"), [
    "package invalid;",
    "",
    "class Plain {}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationNonModelSourceDir, "migrations", "BadNonModelMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000003\",",
    "\tclassName: \"BadNonModelMigration\",",
    "\tmodels: [\"invalid.Plain\"]",
    "})",
    "class BadNonModelMigration extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationNonModelSourceDir,
    migrationNonModelOutputDir,
    "InvalidNonModelMigrationMain",
    "Non-model RailsHx migration compiled successfully.",
    "@:railsMigration model \"invalid.Plain\" must be annotated with @:railsModel"
  );
}

function expectMigrationBadTimestampFailure() {
  mkdirSync(join(migrationBadTimestampSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationBadTimestampSourceDir, "InvalidBadTimestampMigrationMain.hx"), [
    "import migrations.BadTimestampMigration;",
    "",
    "class InvalidBadTimestampMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadTimestampMigration> = BadTimestampMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationBadTimestampSourceDir, "migrations", "BadTimestampMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"tomorrow\",",
    "\tclassName: \"BadTimestampMigration\",",
    "\tmodels: [\"models.User\"]",
    "})",
    "class BadTimestampMigration extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationBadTimestampSourceDir,
    migrationBadTimestampOutputDir,
    "InvalidBadTimestampMigrationMain",
    "Bad-timestamp RailsHx migration compiled successfully.",
    "@:railsMigration timestamp must be a 14-digit string"
  );
}

function expectMigrationUnknownOptionFailure() {
  mkdirSync(join(migrationUnknownOptionSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationUnknownOptionSourceDir, "InvalidUnknownOptionMigrationMain.hx"), [
    "import migrations.BadUnknownOptionMigration;",
    "",
    "class InvalidUnknownOptionMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadUnknownOptionMigration> = BadUnknownOptionMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationUnknownOptionSourceDir, "migrations", "BadUnknownOptionMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000004\",",
    "\tclassName: \"BadUnknownOptionMigration\",",
    "\tmodels: [\"models.User\"],",
    "\tmagic: true",
    "})",
    "class BadUnknownOptionMigration extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationUnknownOptionSourceDir,
    migrationUnknownOptionOutputDir,
    "InvalidUnknownOptionMigrationMain",
    "Unknown-option RailsHx migration compiled successfully.",
    "@:railsMigration unknown option magic"
  );
}

function expectMigrationBadOperationFailure() {
	mkdirSync(join(migrationBadOperationSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationBadOperationSourceDir, "InvalidBadOperationMigrationMain.hx"), [
    "import migrations.BadOperationMigration;",
    "",
    "class InvalidBadOperationMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadOperationMigration> = BadOperationMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationBadOperationSourceDir, "migrations", "BadOperationMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000005\",",
    "\tclassName: \"BadOperationMigration\",",
    "\tmodels: []",
    "})",
    "class BadOperationMigration extends Migration {",
    "\tstatic final tableName = \"todos\";",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddColumn(tableName, \"priority\", IntegerColumn({nullable: false}))",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationBadOperationSourceDir,
    migrationBadOperationOutputDir,
    "InvalidBadOperationMigrationMain",
    "Bad-operation RailsHx migration compiled successfully.",
    "@:railsMigration AddColumn table must be a non-empty String literal"
	);
}

function expectMigrationUnsafeSqlFailure() {
	mkdirSync(join(migrationUnsafeSqlSourceDir, "migrations"), { recursive: true });
	writeFileSync(join(migrationUnsafeSqlSourceDir, "InvalidUnsafeSqlMigrationMain.hx"), [
		"import migrations.BadUnsafeSqlMigration;",
		"",
		"class InvalidUnsafeSqlMigrationMain {",
		"\tstatic function main() {",
		"\t\tvar migration:Class<BadUnsafeSqlMigration> = BadUnsafeSqlMigration;",
		"\t\tSys.println(migration != null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	writeFileSync(join(migrationUnsafeSqlSourceDir, "migrations", "BadUnsafeSqlMigration.hx"), [
		"package migrations;",
		"",
		"import rails.migration.Migration;",
		"import rails.migration.MigrationOperation;",
		"",
		"@:railsMigration({",
		"\ttimestamp: \"20260101000015\",",
		"\tclassName: \"BadUnsafeSqlMigration\",",
		"\tmodels: []",
		"})",
		"class BadUnsafeSqlMigration extends Migration {",
		"\tpublic static final operations:Array<MigrationOperation> = [",
		"\t\tExecuteSql(\"UPDATE todos SET title = 'x'\", \"\")",
		"\t];",
		"}",
		"",
	].join("\n"));
	expectInvalidMigrationCompile(
		migrationUnsafeSqlSourceDir,
		migrationUnsafeSqlOutputDir,
		"InvalidUnsafeSqlMigrationMain",
		"Unsafe-SQL RailsHx migration compiled successfully.",
		"@:railsMigration ExecuteSql expects non-empty literal up and rollback SQL strings."
	);
}

function expectMigrationDuplicateTimestampFailure() {
	mkdirSync(join(migrationDuplicateTimestampSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationDuplicateTimestampSourceDir, "InvalidDuplicateTimestampMigrationMain.hx"), [
    "import migrations.BadDuplicateTimestampA;",
    "import migrations.BadDuplicateTimestampB;",
    "",
    "class InvalidDuplicateTimestampMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar first:Class<BadDuplicateTimestampA> = BadDuplicateTimestampA;",
    "\t\tvar second:Class<BadDuplicateTimestampB> = BadDuplicateTimestampB;",
    "\t\tSys.println(first != null && second != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDuplicateTimestampSourceDir, "migrations", "BadDuplicateTimestampA.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000006\",",
    "\tclassName: \"BadDuplicateTimestampA\",",
    "\tmodels: [\"models.User\"]",
    "})",
    "class BadDuplicateTimestampA extends Migration {}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDuplicateTimestampSourceDir, "migrations", "BadDuplicateTimestampB.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000006\",",
    "\tclassName: \"BadDuplicateTimestampB\",",
    "\tmodels: [\"models.Todo\"]",
    "})",
    "class BadDuplicateTimestampB extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationDuplicateTimestampSourceDir,
    migrationDuplicateTimestampOutputDir,
    "InvalidDuplicateTimestampMigrationMain",
    "Duplicate-timestamp RailsHx migration compiled successfully.",
    "@:railsMigration timestamp 20260101000006 is already used"
  );
}

function expectMigrationForeignKeyOrderFailure() {
  mkdirSync(join(migrationForeignKeyOrderSourceDir, "models"), { recursive: true });
  mkdirSync(join(migrationForeignKeyOrderSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationForeignKeyOrderSourceDir, "InvalidForeignKeyOrderMigrationMain.hx"), [
    "import migrations.BadCreateTodosFirst;",
    "import migrations.BadCreateUsersLater;",
    "",
    "class InvalidForeignKeyOrderMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar todos:Class<BadCreateTodosFirst> = BadCreateTodosFirst;",
    "\t\tvar users:Class<BadCreateUsersLater> = BadCreateUsersLater;",
    "\t\tSys.println(todos != null && users != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationForeignKeyOrderSourceDir, "models", "LateUser.hx"), [
    "package models;",
    "",
    "import rails.ActiveRecord;",
    "",
    "@:railsModel(\"users\")",
    "class LateUser extends ActiveRecord {",
    "\t@:railsColumn({type: \"integer\", primaryKey: true})",
    "\tpublic var id:Int;",
    "",
    "\t@:railsColumn({type: \"string\", nullable: false})",
    "\tpublic var name:String;",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationForeignKeyOrderSourceDir, "models", "EarlyTodo.hx"), [
    "package models;",
    "",
    "import rails.ActiveRecord;",
    "",
    "@:railsModel(\"todos\")",
    "class EarlyTodo extends ActiveRecord {",
    "\t@:railsColumn({type: \"integer\", primaryKey: true})",
    "\tpublic var id:Int;",
    "",
    "\t@:railsColumn({type: \"string\", nullable: false})",
    "\tpublic var title:String;",
    "",
    "\t@:railsColumn({type: \"integer\", nullable: false})",
    "\tpublic var userId:Int;",
    "",
    "\t@:belongsTo public var user:rails.ActiveRecord.BelongsTo<LateUser>;",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationForeignKeyOrderSourceDir, "migrations", "BadCreateTodosFirst.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000007\",",
    "\tclassName: \"BadCreateTodosFirst\",",
    "\tmodels: [\"models.EarlyTodo\"]",
    "})",
    "class BadCreateTodosFirst extends Migration {}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationForeignKeyOrderSourceDir, "migrations", "BadCreateUsersLater.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000008\",",
    "\tclassName: \"BadCreateUsersLater\",",
    "\tmodels: [\"models.LateUser\"]",
    "})",
    "class BadCreateUsersLater extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationForeignKeyOrderSourceDir,
    migrationForeignKeyOrderOutputDir,
    "InvalidForeignKeyOrderMigrationMain",
    "Foreign-key-order RailsHx migration compiled successfully.",
    "@:railsMigration foreign key target table \"users\" is created"
  );
}

function expectMigrationIrreversibleOperationFailure() {
  mkdirSync(join(migrationIrreversibleOperationSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationIrreversibleOperationSourceDir, "InvalidIrreversibleOperationMigrationMain.hx"), [
    "import migrations.BadIrreversibleOperationMigration;",
    "",
    "class InvalidIrreversibleOperationMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadIrreversibleOperationMigration> = BadIrreversibleOperationMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationIrreversibleOperationSourceDir, "migrations", "BadIrreversibleOperationMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000009\",",
    "\tclassName: \"BadIrreversibleOperationMigration\",",
    "\tmodels: []",
    "})",
    "class BadIrreversibleOperationMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tChangeColumn(\"todos\", \"title\", StringColumn({nullable: false}))",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationIrreversibleOperationSourceDir,
    migrationIrreversibleOperationOutputDir,
    "InvalidIrreversibleOperationMigrationMain",
    "Irreversible-operation RailsHx migration compiled successfully.",
    "@:railsMigration ChangeColumn must be wrapped in Reversible(up, down)"
  );
}

function expectMigrationUnknownTableFailure() {
  mkdirSync(join(migrationUnknownTableSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationUnknownTableSourceDir, "InvalidUnknownTableMigrationMain.hx"), [
    "import migrations.BadUnknownTableMigration;",
    "",
    "class InvalidUnknownTableMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadUnknownTableMigration> = BadUnknownTableMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationUnknownTableSourceDir, "migrations", "BadUnknownTableMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "// Demonstrates fail-closed table validation: knownModels gives the compiler",
    "// the existing typed schema, so misspelled table names are rejected before",
    "// Rails sees the migration.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000010\",",
    "\tclassName: \"BadUnknownTableMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"]",
    "})",
    "class BadUnknownTableMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddIndex(\"todoss\", \"title\", {unique: false})",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationUnknownTableSourceDir,
    migrationUnknownTableOutputDir,
    "InvalidUnknownTableMigrationMain",
    "Unknown-table RailsHx migration compiled successfully.",
    "@:railsMigration AddIndex table references unknown table \"todoss\""
  );
}

function expectMigrationUnknownColumnFailure() {
  mkdirSync(join(migrationUnknownColumnSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationUnknownColumnSourceDir, "InvalidUnknownColumnMigrationMain.hx"), [
    "import migrations.BadUnknownColumnMigration;",
    "",
    "class InvalidUnknownColumnMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadUnknownColumnMigration> = BadUnknownColumnMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationUnknownColumnSourceDir, "migrations", "BadUnknownColumnMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "// Demonstrates fail-closed column validation: typed model metadata lets",
    "// RailsHx reject invalid index references while preserving Rails-shaped",
    "// string/symbol output in the generated migration.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000011\",",
    "\tclassName: \"BadUnknownColumnMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"]",
    "})",
    "class BadUnknownColumnMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddIndex(\"todos\", \"missing_title\", {unique: false})",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationUnknownColumnSourceDir,
    migrationUnknownColumnOutputDir,
    "InvalidUnknownColumnMigrationMain",
    "Unknown-column RailsHx migration compiled successfully.",
    "@:railsMigration AddIndex column references unknown column \"missing_title\" on table \"todos\""
  );
}

function expectMigrationUnsafeIndexNameFailure() {
  mkdirSync(join(migrationUnsafeIndexNameSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationUnsafeIndexNameSourceDir, "InvalidUnsafeIndexNameMigrationMain.hx"), [
    "import migrations.BadUnsafeIndexNameMigration;",
    "",
    "class InvalidUnsafeIndexNameMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadUnsafeIndexNameMigration> = BadUnsafeIndexNameMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationUnsafeIndexNameSourceDir, "migrations", "BadUnsafeIndexNameMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000018\",",
    "\tclassName: \"BadUnsafeIndexNameMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"]",
    "})",
    "class BadUnsafeIndexNameMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddIndex(\"todos\", \"title\", {name: \"../bad_index\"})",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationUnsafeIndexNameSourceDir,
    migrationUnsafeIndexNameOutputDir,
    "InvalidUnsafeIndexNameMigrationMain",
    "Unsafe index-name RailsHx migration compiled successfully.",
    "@:railsMigration MigrationIndex name must be a safe Rails identifier"
  );
}

function expectMigrationUnsafeForeignKeyNameFailure() {
  mkdirSync(join(migrationUnsafeForeignKeyNameSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationUnsafeForeignKeyNameSourceDir, "InvalidUnsafeForeignKeyNameMigrationMain.hx"), [
    "import migrations.BadUnsafeForeignKeyNameMigration;",
    "",
    "class InvalidUnsafeForeignKeyNameMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadUnsafeForeignKeyNameMigration> = BadUnsafeForeignKeyNameMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationUnsafeForeignKeyNameSourceDir, "migrations", "BadUnsafeForeignKeyNameMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000019\",",
    "\tclassName: \"BadUnsafeForeignKeyNameMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\", \"models.User\"]",
    "})",
    "class BadUnsafeForeignKeyNameMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddForeignKey(\"todos\", \"users\", {column: \"user_id\", name: \"../bad_fk\"})",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationUnsafeForeignKeyNameSourceDir,
    migrationUnsafeForeignKeyNameOutputDir,
    "InvalidUnsafeForeignKeyNameMigrationMain",
    "Unsafe foreign-key-name RailsHx migration compiled successfully.",
    "@:railsMigration ForeignKey name must be a safe Rails identifier"
  );
}

function expectMigrationUnsafeCheckConstraintNameFailure() {
  mkdirSync(join(migrationUnsafeCheckConstraintNameSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationUnsafeCheckConstraintNameSourceDir, "InvalidUnsafeCheckConstraintNameMigrationMain.hx"), [
    "import migrations.BadUnsafeCheckConstraintNameMigration;",
    "",
    "class InvalidUnsafeCheckConstraintNameMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadUnsafeCheckConstraintNameMigration> = BadUnsafeCheckConstraintNameMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationUnsafeCheckConstraintNameSourceDir, "migrations", "BadUnsafeCheckConstraintNameMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000020\",",
    "\tclassName: \"BadUnsafeCheckConstraintNameMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"]",
    "})",
    "class BadUnsafeCheckConstraintNameMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddCheckConstraint(\"todos\", \"priority >= 0\", {name: \"../bad_check\"})",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationUnsafeCheckConstraintNameSourceDir,
    migrationUnsafeCheckConstraintNameOutputDir,
    "InvalidUnsafeCheckConstraintNameMigrationMain",
    "Unsafe check-constraint-name RailsHx migration compiled successfully.",
    "@:railsMigration CheckConstraint name must be a safe Rails identifier"
  );
}

function expectMigrationExternalTableAllowed() {
  mkdirSync(join(migrationExternalTableSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationExternalTableSourceDir, "ExternalTableMigrationMain.hx"), [
    "import migrations.ExternalTableMigration;",
    "",
    "class ExternalTableMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<ExternalTableMigration> = ExternalTableMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationExternalTableSourceDir, "migrations", "ExternalTableMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "// Demonstrates the Rails-owned table escape path: externalTables keeps",
    "// known typed models checked while allowing deliberate integration with",
    "// pre-existing/engine-owned Rails schema that Haxe does not own.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000012\",",
    "\tclassName: \"ExternalTableMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"],",
    "\texternalTables: [\"legacy_events\"]",
    "})",
    "class ExternalTableMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddIndex(\"legacy_events\", \"external_id\", {unique: true})",
    "\t];",
    "}",
    "",
  ].join("\n"));
  compileValidMigration(
    migrationExternalTableSourceDir,
    migrationExternalTableOutputDir,
    "ExternalTableMigrationMain"
  );
  const migrationRuby = readFileSync(join(migrationExternalTableOutputDir, "db", "migrate", "20260101000012_external_table_migration.rb"), "utf8");
  if (!migrationRuby.includes("add_index :legacy_events, :external_id, unique: true")) {
    console.error("External-table migration did not emit the expected unchecked Rails index.");
    process.exit(1);
  }
}

function expectMigrationUnsafeExternalTableFailure() {
  mkdirSync(join(migrationUnsafeExternalTableSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationUnsafeExternalTableSourceDir, "UnsafeExternalTableMigrationMain.hx"), [
    "import migrations.UnsafeExternalTableMigration;",
    "",
    "class UnsafeExternalTableMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<UnsafeExternalTableMigration> = UnsafeExternalTableMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationUnsafeExternalTableSourceDir, "migrations", "UnsafeExternalTableMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000013\",",
    "\tclassName: \"UnsafeExternalTableMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"],",
    "\texternalTables: [\"../legacy/events\"]",
    "})",
    "class UnsafeExternalTableMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddIndex(\"legacy_events\", \"external_id\", {unique: true})",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationUnsafeExternalTableSourceDir,
    migrationUnsafeExternalTableOutputDir,
    "UnsafeExternalTableMigrationMain",
    "Unsafe externalTables RailsHx migration compiled successfully.",
    "@:railsMigration externalTables entries must be safe Rails table identifiers"
  );
}

function expectMigrationDropTableReversibleOutput() {
  mkdirSync(join(migrationDropTableSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationDropTableSourceDir, "DropTableMigrationMain.hx"), [
    "import migrations.DropTableMigration;",
    "",
    "class DropTableMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<DropTableMigration> = DropTableMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDropTableSourceDir, "migrations", "DropTableMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "// Demonstrates reversible destructive migration validation: DropTable is",
    "// allowed only inside Reversible, and knownModels makes the table reference",
    "// compile-time checked without emitting another create_table.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000013\",",
    "\tclassName: \"DropTableMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"]",
    "})",
    "class DropTableMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tReversible([DropTable(\"todos\")], [])",
    "\t];",
    "}",
    "",
  ].join("\n"));
  compileValidMigration(
    migrationDropTableSourceDir,
    migrationDropTableOutputDir,
    "DropTableMigrationMain"
  );
  const migrationRuby = readFileSync(join(migrationDropTableOutputDir, "db", "migrate", "20260101000013_drop_table_migration.rb"), "utf8");
  if (!migrationRuby.includes("drop_table :todos")) {
    console.error("Drop-table migration did not emit the expected reversible drop_table statement.");
    process.exit(1);
  }
}

function expectMigrationSnapshotOperationsOutput() {
  mkdirSync(join(migrationSnapshotOpsSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationSnapshotOpsSourceDir, "SnapshotOperationsMigrationMain.hx"), [
    "import migrations.SnapshotOperationsMigration;",
    "",
    "class SnapshotOperationsMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<SnapshotOperationsMigration> = SnapshotOperationsMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationSnapshotOpsSourceDir, "migrations", "SnapshotOperationsMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "import rails.migration.MigrationOperation.CreateTableItem;",
    "",
    "// Demonstrates production snapshot migration operations. The migration owns",
    "// explicit historical operations instead of deriving from mutable model",
    "// metadata, which keeps old migrations stable as models evolve.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000014\",",
    "\tclassName: \"SnapshotOperationsMigration\",",
    "\tversion: \"8.1\",",
    "\tmodels: []",
    "})",
    "class SnapshotOperationsMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tCreateTable(\"audit_events\", {",
    "\t\t\tcolumns: [",
    "\t\t\t\tColumn(\"title\", StringColumn({nullable: false, limit: 120})),",
    "\t\t\t\tColumn(\"amount\", DecimalColumn({precision: 10, scale: 2})),",
    "\t\t\t\tReference(\"user\", {nullable: false, foreignKey: true}),",
    "\t\t\t\tIndex([\"user_id\", \"title\"], {unique: true})",
    "\t\t\t],",
    "\t\t\ttimestamps: true",
    "\t\t}),",
    "\t\tAddReference(\"audit_events\", \"account\", {index: false}),",
    "\t\tAddCompositeIndex(\"audit_events\", [\"account_id\", \"title\"], {}),",
    "\t\tChangeNull(\"audit_events\", \"title\", false),",
    "\t\tAddCheckConstraint(\"audit_events\", \"amount >= 0\", {name: \"amount_non_negative\"}),",
    "\t\tExecuteSql(\"UPDATE audit_events SET title = 'untitled' WHERE title IS NULL\", \"UPDATE audit_events SET title = NULL WHERE title = 'untitled'\"),",
    "\t\tDataMigration(\"UPDATE audit_events SET amount = 0 WHERE amount IS NULL\", \"UPDATE audit_events SET amount = NULL WHERE amount = 0\"),",
    "\t\tReversible([",
    "\t\t\tRenameColumn(\"audit_events\", \"title\", \"headline\"),",
    "\t\t\tRenameTable(\"audit_events\", \"audit_entries\"),",
    "\t\t\tRemoveCheckConstraint(\"audit_entries\", \"amount_non_negative\"),",
    "\t\t\tRemoveReference(\"audit_entries\", \"account\", {})",
    "\t\t], [",
    "\t\t\tAddReference(\"audit_entries\", \"account\", {}),",
    "\t\t\tAddCheckConstraint(\"audit_entries\", \"amount >= 0\", {name: \"amount_non_negative\"}),",
    "\t\t\tRenameTable(\"audit_entries\", \"audit_events\"),",
    "\t\t\tRenameColumn(\"audit_events\", \"headline\", \"title\")",
    "\t\t])",
    "\t];",
    "}",
    "",
  ].join("\n"));
  compileValidMigration(
    migrationSnapshotOpsSourceDir,
    migrationSnapshotOpsOutputDir,
    "SnapshotOperationsMigrationMain"
  );
  const migrationRuby = readFileSync(join(migrationSnapshotOpsOutputDir, "db", "migrate", "20260101000014_snapshot_operations_migration.rb"), "utf8");
  for (const expected of [
    "class SnapshotOperationsMigration < ActiveRecord::Migration[8.1]",
    "create_table :audit_events do |t|",
    "t.string :title, null: false, limit: 120",
    "t.decimal :amount, precision: 10, scale: 2",
    "t.references :user, null: false, foreign_key: true",
    "t.index [:user_id, :title], unique: true",
    "t.timestamps",
    "add_reference :audit_events, :account, index: false",
    "add_index :audit_events, [:account_id, :title]",
    "change_column_null :audit_events, :title, false",
    "add_check_constraint :audit_events, \"amount >= 0\", name: \"amount_non_negative\"",
    "execute \"UPDATE audit_events SET title = 'untitled' WHERE title IS NULL\"",
    "execute \"UPDATE audit_events SET title = NULL WHERE title = 'untitled'\"",
    "execute \"UPDATE audit_events SET amount = 0 WHERE amount IS NULL\"",
    "execute \"UPDATE audit_events SET amount = NULL WHERE amount = 0\"",
    "rename_column :audit_events, :title, :headline",
    "rename_table :audit_events, :audit_entries",
    "remove_check_constraint :audit_entries, name: \"amount_non_negative\"",
    "remove_reference :audit_entries, :account",
  ]) {
    if (!migrationRuby.includes(expected)) {
      console.error(`Snapshot operation migration missing expected line: ${expected}`);
      process.exit(1);
    }
  }
}

function expectMigrationHistoricalAddColumnAllowed() {
  mkdirSync(join(migrationHistoricalAddColumnSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationHistoricalAddColumnSourceDir, "HistoricalAddColumnMigrationMain.hx"), [
    "import migrations.HistoricalAddColumnMigration;",
    "",
    "class HistoricalAddColumnMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<HistoricalAddColumnMigration> = HistoricalAddColumnMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationHistoricalAddColumnSourceDir, "migrations", "HistoricalAddColumnMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "// Demonstrates the historical-snapshot rule: knownModels validates that",
    "// table/column references are real in today's typed model contract, but it",
    "// does not mean every current model field already existed when this old",
    "// migration ran. AddColumn(\"todos\", \"title\", ...) stays valid even",
    "// though models.Todo now declares title.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000016\",",
    "\tclassName: \"HistoricalAddColumnMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"]",
    "})",
    "class HistoricalAddColumnMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddColumn(\"todos\", \"title\", StringColumn({nullable: false}))",
    "\t];",
    "}",
    "",
  ].join("\n"));
  compileValidMigration(
    migrationHistoricalAddColumnSourceDir,
    migrationHistoricalAddColumnOutputDir,
    "HistoricalAddColumnMigrationMain"
  );
  const migrationRuby = readFileSync(join(migrationHistoricalAddColumnOutputDir, "db", "migrate", "20260101000016_historical_add_column_migration.rb"), "utf8");
  if (!migrationRuby.includes("add_column :todos, :title, :string, null: false")) {
    console.error("Historical AddColumn migration did not emit the expected add_column statement.");
    process.exit(1);
  }
}

function expectMigrationDuplicateAddColumnFailure() {
  mkdirSync(join(migrationDuplicateAddColumnSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationDuplicateAddColumnSourceDir, "InvalidDuplicateAddColumnMigrationMain.hx"), [
    "import migrations.BadDuplicateAddColumnMigration;",
    "",
    "class InvalidDuplicateAddColumnMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadDuplicateAddColumnMigration> = BadDuplicateAddColumnMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDuplicateAddColumnSourceDir, "migrations", "BadDuplicateAddColumnMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "// Demonstrates same-snapshot duplicate detection. The first AddColumn is a",
    "// valid historical operation; the second is rejected because this migration",
    "// snapshot would emit the same column twice.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000017\",",
    "\tclassName: \"BadDuplicateAddColumnMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"]",
    "})",
    "class BadDuplicateAddColumnMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddColumn(\"todos\", \"title\", StringColumn({nullable: false})),",
    "\t\tAddColumn(\"todos\", \"title\", StringColumn({nullable: false}))",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationDuplicateAddColumnSourceDir,
    migrationDuplicateAddColumnOutputDir,
    "InvalidDuplicateAddColumnMigrationMain",
    "Duplicate AddColumn RailsHx migration compiled successfully.",
    "@:railsMigration AddColumn name references column \"title\" already emitted by this migration snapshot on table \"todos\""
  );
}

function expectInvalidTemplateLocalsFailure() {
  mkdirSync(join(invalidSourceDir, "controllers"), { recursive: true });
  writeFileSync(join(invalidSourceDir, "InvalidMain.hx"), [
    "import controllers.BadTodosController;",
    "",
    "class InvalidMain {",
    "\tstatic function main() {",
    "\t\tvar controller:BadTodosController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "controllers", "BadTodosController.hx"), [
    "package controllers;",
    "",
    "import models.Todo;",
    "import rails.action_view.Template;",
    "import rails.macros.ViewMacro;",
    "import views.TodoIndexView;",
    "",
    "typedef TodoIndexLocals = {",
    "\tvar todos:Array<Todo>;",
    "}",
    "",
    "@:railsController",
    "class BadTodosController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = [];",
    "",
    "\tpublic function index() {",
    "\t\tvar todos = Todo.incomplete();",
    "\t\tViewMacro.renderTemplate(this, (Template.of(TodoIndexView) : Template<TodoIndexLocals>), {items: todos});",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${invalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      join(exampleDir, "src_haxe"),
      "-cp",
      invalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid ViewMacro.renderTemplate locals compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("ViewMacro.renderTemplate locals do not match the Template<TLocals> contract.")
      && !output.includes("TodoIndexLocals")
      && !output.includes("has no field todos")) {
      console.error("Invalid ViewMacro.renderTemplate locals failed, but not with the expected typed locals error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid ViewMacro.renderTemplate locals check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectRawErbRequiresOptInFailure() {
  mkdirSync(join(rawErbInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(rawErbInvalidSourceDir, "InvalidRawErbMain.hx"), [
    "import views.BadRawErbView;",
    "",
    "class InvalidRawErbMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadRawErbView> = BadRawErbView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(rawErbInvalidSourceDir, "views", "BadRawErbView.hx"), [
    "package views;",
    "",
    "@:railsTemplate(\"controllers/todos/bad\")",
    "class BadRawErbView {",
    "\tpublic static var body:String = \"<%= dangerous %>\";",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${rawErbInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      rawErbInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidRawErbMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Raw ERB template without @:railsAllowRawErb compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("@:railsTemplate raw ERB blocks require @:railsAllowRawErb")) {
      console.error("Raw ERB template failed, but not with the expected escape-hatch error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run raw ERB escape-hatch check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTypedTemplateAstFieldFailure() {
  mkdirSync(join(typedTemplateInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedTemplateInvalidSourceDir, "InvalidTypedTemplateMain.hx"), [
    "import views.BadTypedTemplateView;",
    "",
    "class InvalidTypedTemplateMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedTemplateView> = BadTypedTemplateView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedTemplateInvalidSourceDir, "views", "BadTypedTemplateView.hx"), [
    "package views;",
    "",
    "import models.Todo;",
    "import rails.action_view.HtmlAttr;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_typed\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedTemplateView {",
    "\tpublic static function render(todos:Array<Todo>):HtmlNode {",
    "\t\treturn HtmlNode.Element(\"div\", [HtmlAttr.Static(\"class\", \"bad\")], [",
    "\t\t\tHtmlNode.ExprText(todos[0].missingTitle)",
    "\t\t]);",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${typedTemplateInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      typedTemplateInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedTemplateMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid @:railsTemplateAst field access compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("missingTitle") && !output.includes("has no field")) {
      console.error("Invalid @:railsTemplateAst field access failed, but not with the expected typed field error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid @:railsTemplateAst field check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTypedPartialLocalsFailure() {
  mkdirSync(join(typedPartialInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedPartialInvalidSourceDir, "InvalidTypedPartialMain.hx"), [
    "import views.BadTypedPartialView;",
    "",
    "class InvalidTypedPartialMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedPartialView> = BadTypedPartialView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedPartialInvalidSourceDir, "views", "BadTypedPartialView.hx"), [
    "package views;",
    "",
    "import models.Todo;",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Template;",
    "import views.TodoSummaryView;",
    "import views.TodoSummaryView.TodoSummaryLocals;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_partial\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedPartialView {",
    "\tpublic static function render(todos:Array<Todo>):HtmlNode {",
    "\t\treturn H.partial((Template.of(TodoSummaryView) : Template<TodoSummaryLocals>), {items: todos});",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${typedPartialInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      typedPartialInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedPartialMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid H.partial locals compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("TodoSummaryLocals") && !output.includes("has no field todos") && !output.includes("Object requires field todos")) {
      console.error("Invalid H.partial locals failed, but not with the expected typed locals error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid H.partial locals check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function compileCheckedAttrFixture(sourceDir, outputDir, mainClass, viewClass, viewBody, options = {}) {
  mkdirSync(join(sourceDir, "views"), { recursive: true });
  writeFileSync(join(sourceDir, `${mainClass}.hx`), [
    `import views.${viewClass};`,
    "",
    `class ${mainClass} {`,
    "\tstatic function main() {",
    `\t\tvar view:Class<${viewClass}> = ${viewClass};`,
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(sourceDir, "views", `${viewClass}.hx`), viewBody.join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${outputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      sourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      mainClass,
    ], { allowFailure: options.allowFailure === true });
    return result;
  }
  if (!sawCandidate) {
    console.error("Unable to run checked H.attr helper fixture; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectCheckedAttrHelpersOutput() {
  compileCheckedAttrFixture(checkedAttrSourceDir, checkedAttrOutputDir, "CheckedAttrMain", "CheckedAttrView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/checked_attrs\")",
    "@:railsTemplateAst(\"render\")",
    "class CheckedAttrView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.fragment([",
    "\t\t\tH.el(\"section\", [H.role(\"status\"), H.aria(\"live\", \"polite\"), H.dataBool(\"railshx-scroll\")], [H.text(\"Ready\")]),",
    "\t\t\tH.linkTo(\"Users\", \"/users\", [H.data(\"turbo_frame\", \"railshx-user-frame\"), H.aria(\"label\", \"Manage users\")]),",
    "\t\t\tH.buttonTag(\"Save draft\", [H.attr(\"type\", \"button\"), H.className(\"draft-button\")]),",
    "\t\t\t<button_tag type=\"button\" data-confirm=\"Archive item?\">Archive</button_tag>,",
    "\t\t\tH.submitTag(\"Search\", [H.className(\"search-submit\"), H.data(\"turbo\", \"false\")]),",
    "\t\t\t<submit_tag value=\"Filter\" disabled=${true} />,",
    "\t\t\tH.textFieldTag(\"status\", \"open\", [H.className(\"status-filter\")]),",
    "\t\t\t<text_field_tag name=\"query\" value=\"typed search\" placeholder=\"Search\" data-controller=\"search\" />,",
    "\t\t\tH.searchFieldTag(\"term\", \"rails\", [H.className(\"term-search\")]),",
    "\t\t\t<search_field_tag name=\"filter\" value=\"typed\" placeholder=\"Filter\" data-controller=\"filter\" />,",
    "\t\t\tH.emailFieldTag(\"contact_email\", \"ops@example.test\", [H.className(\"email-input\")]),",
    "\t\t\t<email_field_tag name=\"reply_to\" value=\"support@example.test\" placeholder=\"Email\" autocomplete=\"email\" />,",
    "\t\t\tH.telephoneFieldTag(\"contact_phone\", \"5551234567\", [H.className(\"phone-input\")]),",
    "\t\t\t<telephone_field_tag name=\"support_phone\" value=\"8005551212\" placeholder=\"Phone\" autocomplete=\"tel\" />,",
    "\t\t\tH.urlFieldTag(\"homepage\", \"https://example.test\", [H.className(\"url-input\")]),",
    "\t\t\t<url_field_tag name=\"callback_url\" value=\"https://example.test/callback\" placeholder=\"URL\" data-controller=\"url\" />,",
    "\t\t\tH.numberFieldTag(\"quantity\", 3.5, [H.attr(\"min\", \"0\")]),",
    "\t\t\t<number_field_tag name=\"priority\" value=${2.5} min=${0} step=\"0.5\" />,",
    "\t\t\tH.rangeFieldTag(\"completion\", 0.75, [H.attr(\"max\", \"1\")]),",
    "\t\t\t<range_field_tag name=\"progress\" value=${0.5} min=${0} max=${1} step=\"0.1\" />,",
    "\t\t\tH.colorFieldTag(\"accent\", \"#336699\", [H.className(\"accent-picker\")]),",
    "\t\t\t<color_field_tag name=\"brand_color\" value=\"#ffcc00\" data-controller=\"palette\" />,",
    "\t\t\tH.dateFieldTag(\"due_on\", \"2026-06-23\", [H.className(\"date-input\")]),",
    "\t\t\t<date_field_tag name=\"starts_on\" value=\"2026-07-01\" min=\"2026-01-01\" data-controller=\"date\" />,",
    "\t\t\tH.timeFieldTag(\"starts_at\", \"09:30\", [H.attrExpr(\"include_seconds\", true)]),",
    "\t\t\t<time_field_tag name=\"ends_at\" value=\"17:45\" min=\"08:00\" max=\"18:00\" step=${60} />,",
    "\t\t\tH.datetimeFieldTag(\"scheduled_at\", \"2026-06-23T09:30\", [H.className(\"datetime-input\")]),",
    "\t\t\t<datetime_field_tag name=\"published_at\" value=\"2026-07-01T17:45\" min=\"2026-01-01T00:00\" data-controller=\"datetime\" />,",
    "\t\t\tH.monthFieldTag(\"billing_month\", \"2026-06\", [H.className(\"month-input\")]),",
    "\t\t\t<month_field_tag name=\"archive_month\" value=\"2026-07\" min=\"2026-01\" data-controller=\"month\" />,",
    "\t\t\tH.weekFieldTag(\"billing_week\", \"2026-W26\", [H.className(\"week-input\")]),",
    "\t\t\t<week_field_tag name=\"archive_week\" value=\"2026-W27\" min=\"2026-W01\" data-controller=\"week\" />,",
    "\t\t\tH.passwordFieldTag(\"admin_password\", null, [H.attr(\"autocomplete\", \"current-password\")]),",
    "\t\t\t<password_field_tag name=\"token\" value=\"secret\" autocomplete=\"one-time-code\" />,",
    "\t\t\tH.hiddenFieldTag(\"return_to\", \"/todos\", [H.data(\"tracked\", \"true\")]),",
    "\t\t\t<hidden_field_tag name=\"source\" value=\"typed\" data-controller=\"source\" />,",
    "\t\t\tH.fileFieldTag(\"avatar\", [H.attr(\"accept\", \"image/png\")]),",
    "\t\t\t<file_field_tag name=\"attachment\" multiple=${true} direct_upload=${true} />,",
    "\t\t\tH.textAreaTag(\"notes\", \"Draft note\", [H.attr(\"rows\", \"4\")]),",
    "\t\t\t<text_area_tag name=\"comment\" rows=${3}>Typed comment</text_area_tag>,",
    "\t\t\tH.checkBoxTag(\"published\", \"1\", true, [H.className(\"published-check\")]),",
    "\t\t\t<check_box_tag name=\"archived\" value=\"yes\" checked=${false} data-controller=\"archive\" />,",
    "\t\t\tH.radioButtonTag(\"visibility\", \"public\", true, [H.className(\"visibility-choice\")]),",
    "\t\t\t<radio_button_tag name=\"visibility\" value=\"private\" checked=${false} data-controller=\"visibility\" />,",
    "\t\t\tH.imageTag(\"avatar.png\", [H.attr(\"alt\", \"Profile avatar\"), H.className(\"avatar\"), H.data(\"direct-upload-url\", \"/rails/active_storage/direct_uploads\")]),",
    "\t\t\t<image_tag src=\"badge.png\" alt=\"RailsHx badge\" class=\"badge\" />,",
    "\t\t\tH.pictureTag(\"hero.webp\", [H.attr(\"alt\", \"Hero image\"), H.className(\"hero-picture\")]),",
    "\t\t\t<picture_tag src=\"team.avif\" alt=\"Team photo\" class=\"team-picture\" />,",
    "\t\t\tH.faviconLinkTag(\"favicon.ico\", [H.attr(\"rel\", \"shortcut icon\")]),",
    "\t\t\t<favicon_link_tag src=\"touch-icon.png\" rel=\"apple-touch-icon\" type=\"image/png\" />,",
    "\t\t\tH.preloadLinkTag(\"application.css\", [H.attr(\"as\", \"style\"), H.attr(\"type\", \"text/css\")]),",
    "\t\t\t<preload_link_tag src=\"app.js\" as=\"script\" crossorigin=\"anonymous\" />,",
    "\t\t\tH.javascriptIncludeTag(\"dashboard\", [H.boolAttr(\"defer\"), H.data(\"turbo-track\", \"reload\")]),",
    "\t\t\t<javascript_include_tag src=\"analytics\" defer=${true} type=\"module\" />,",
    "\t\t\tH.javascriptTag(\"window.RailsHxReady = true;\", [H.boolAttr(\"nonce\")]),",
    "\t\t\t<javascript_tag content=\"console.log('typed helper');\" nonce=${true} />,",
    "\t\t\tH.autoDiscoveryLinkTag(\"rss\", \"/feed.xml\", [H.attr(\"title\", \"Todo feed\")]),",
    "\t\t\t<auto_discovery_link_tag type=\"atom\" url=\"/feed.atom\" title=\"Atom feed\" />,",
    "\t\t\tH.audioTag(\"intro.mp3\", [H.boolAttr(\"controls\"), H.className(\"intro-audio\")]),",
    "\t\t\t<audio_tag src=\"notify.wav\" autoplay=${true} controls=${true} />,",
    "\t\t\tH.videoTag(\"demo.mp4\", [H.boolAttr(\"controls\"), H.attr(\"poster\", \"demo.png\")]),",
    "\t\t\t<video_tag src=\"walkthrough.webm\" controls=${true} muted=${true} />,",
    "\t\t\tH.mailTo(\"support@example.test\", null, [H.className(\"support-link\")]),",
    "\t\t\t<mail_to email=\"admin@example.test\" text=\"Email admin\" class=\"admin-link\" />,",
    "\t\t\t<mail_to email=\"ops@example.test\">Ops desk</mail_to>,",
    "\t\t\tH.phoneTo(\"1234567890\", null, [H.className(\"phone-link\"), H.attr(\"country_code\", \"01\")]),",
    "\t\t\t<phone_to phone=\"5551234567\" text=\"Call support\" class=\"support-phone\" />,",
    "\t\t\t<phone_to phone=\"8005551212\" country_code=\"1\">Call sales</phone_to>,",
    "\t\t\tH.smsTo(\"5155555785\", null, [H.className(\"sms-link\"), H.attr(\"body\", \"Status update\")]),",
    "\t\t\t<sms_to phone=\"5155555785\" text=\"Text support\" class=\"support-sms\" />,",
    "\t\t\t<sms_to phone=\"8005551212\" country_code=\"1\" body=\"Need help\">Text sales</sms_to>,",
    "\t\t\tH.pluralize(2, \"task\", null),",
    "\t\t\t<pluralize count=${3} singular=\"person\" plural=\"people\" />,",
    "\t\t\tH.simpleFormat(\"First line\\nSecond line\", [H.className(\"formatted-copy\")]),",
    "\t\t\t<simple_format text=\"Inline copy\" class=\"inline-copy\" />,",
    "\t\t\tH.truncate(\"Ship the typed template helper surface\", 12, \"...\"),",
    "\t\t\t<truncate text=\"Inline helper copy\" length=${10} omission=\"...\" />,",
    "\t\t\tH.excerpt(\"This is a very beautiful morning\", \"very\", 3, \"...\"),",
    "\t\t\t<excerpt text=\"This next thing is an example\" phrase=\"ex\" radius=${2} omission=\"...\" />,",
    "\t\t\tH.highlight(\"You searched for: rails\", \"rails\", \"<em>\\\\1</em>\", true),",
    "\t\t\t<highlight text=\"You searched for: ruby\" phrase=\"ruby\" highlighter=\"match: \\\\1\" sanitize=${false} />,",
    "\t\t\tH.wordWrap(\"Once upon a time\", 8, \" / \"),",
    "\t\t\t<word_wrap text=\"Typed helper output wraps neatly\" line_width=${12} break_sequence=\" | \" />,",
    "\t\t\tH.sanitize(\"<b data-safe='yes'>Bold</b><script>bad()</script>\", [\"b\"], [\"data-safe\"]),",
    "\t\t\t<sanitize html=\"Inline sanitize copy\" tags=${[\"i\"]} />,",
    "\t\t\tH.sanitizeCss(\"width: 100%; background-image: url('http://example.test'); height: 100%;\"),",
    "\t\t\t<sanitize_css style=\"color: red; position: absolute;\" />,",
    "\t\t\tH.stripTags(\"<b>Bold</b> no more\"),",
    "\t\t\t<strip_tags html=\"Inline copy\" />,",
    "\t\t\tH.stripLinks(\"Blog: <a href='https://example.test'>Visit</a>\"),",
    "\t\t\t<strip_links html=\"Plain link text\" />,",
    "\t\t\tH.toSentence([\"Draft\", \"Review\", \"Ship\"], \", \", \" or \", \", or \"),",
    "\t\t\t<to_sentence items=${[\"One\", \"Two\"]} two_words_connector=\" plus \" />,",
    "\t\t\tH.escapeOnce(\"1 < 2 &amp; 3\"),",
    "\t\t\t<escape_once html=\"Accept & Checkout\" />,",
    "\t\t\tH.cdataSection(\"<hello world>\"),",
    "\t\t\t<cdata_section content=\"inline cdata\" />,",
    "\t\t\tH.safeJoin([\"Draft\", \"Review\", \"Ship\"], \" / \"),",
    "\t\t\t<safe_join items=${[\"One\", \"Two\"]} separator=\" + \" />,",
    "\t\t\tH.tokenList([\"btn\", \"btn-primary\", \"is-active\"]),",
    "\t\t\t<token_list tokens=${[\"card\", \"is-selected\"]} />,",
    "\t\t\tH.classNames([\"btn\", \"is-disabled\"]),",
    "\t\t\t<class_names tokens=${[\"panel\", \"is-open\"]} />,",
    "\t\t\tH.cycle([\"odd\", \"even\"], null),",
    "\t\t\t<cycle values=${[\"red\", \"green\", \"blue\"]} name=\"colors\" />,",
    "\t\t\tH.currentCycle(null),",
    "\t\t\t<current_cycle name=\"colors\" />,",
    "\t\t\tH.resetCycle(null),",
    "\t\t\t<reset_cycle name=\"colors\" />,",
    "\t\t\tH.timeAgoInWords(Date.now(), true),",
    "\t\t\t<time_ago_in_words from=${Date.now()} include_seconds=${false} />,",
    "\t\t\tH.distanceOfTimeInWords(Date.now(), Date.now(), true),",
    "\t\t\t<distance_of_time_in_words from=${Date.now()} to=${Date.now()} include_seconds=${false} />,",
    "\t\t\tH.timeTag(Date.now(), \"Right now\", [H.className(\"timestamp\")]),",
    "\t\t\t<time_tag time=${Date.now()} text=\"Updated\" class=\"updated-at\" data-controller=\"clock\" />,",
    "\t\t\tH.numberToCurrency(12.5, \"$\", 2),",
    "\t\t\t<number_to_currency number=${99.95} unit=\"USD \" precision=${0} />,",
    "\t\t\tH.numberToPercentage(42.5, 1),",
    "\t\t\t<number_to_percentage number=${87.25} precision=${2} />,",
    "\t\t\tH.numberToHuman(1234567.0, 2),",
    "\t\t\t<number_to_human number=${987654.0} precision=${3} />,",
    "\t\t\tH.numberToHumanSize(1048576.0, 2),",
    "\t\t\t<number_to_human_size number=${1536000.0} precision=${3} />,",
    "\t\t\tH.numberWithPrecision(12345.6789, 2, false, \",\", \".\", true),",
    "\t\t\t<number_with_precision number=${9876.54321} precision=${3} significant=${true} delimiter=\" \" separator=\",\" strip_insignificant_zeros=${false} />,",
    "\t\t\tH.numberWithDelimiter(1234567.89, \" \", \",\"),",
    "\t\t\t<number_with_delimiter number=${987654.32} delimiter=\".\" separator=\",\" />,",
    "\t\t\tH.numberToDelimited(1234567.89, \" \", \",\"),",
    "\t\t\t<number_to_delimited number=${987654.32} delimiter=\".\" separator=\",\" />,",
    "\t\t\tH.numberToPhone(\"5551234567\", true, \"-\", \"9\", 1),",
    "\t\t\t<number_to_phone number=\"8005551212\" area_code=${true} delimiter=\".\" extension=\"42\" country_code=${1} />",
    "\t\t]);",
    "\t}",
    "}",
    "",
  ]);

  const generated = readFileSync(join(checkedAttrOutputDir, "app", "views", "controllers", "todos", "checked_attrs.html.erb"), "utf8");
  for (const expected of [
    '<section role="status" aria-live="polite" data-railshx-scroll>Ready</section>',
    '<%= link_to "Users", "/users", data: {turbo_frame: "railshx-user-frame"}, aria: {label: "Manage users"} %>',
    '<%= button_tag "Save draft", type: "button", class: "draft-button" %>',
    '<%= button_tag "Archive", type: "button", data: {confirm: "Archive item?"} %>',
    '<%= submit_tag "Search", class: "search-submit", data: {turbo: false} %>',
    '<%= submit_tag "Filter", disabled: true %>',
    '<%= text_field_tag :status, "open", class: "status-filter" %>',
    '<%= text_field_tag :query, "typed search", placeholder: "Search", data: {controller: "search"} %>',
    '<%= search_field_tag :term, "rails", class: "term-search" %>',
    '<%= search_field_tag :filter, "typed", placeholder: "Filter", data: {controller: "filter"} %>',
    '<%= email_field_tag :contact_email, "ops@example.test", class: "email-input" %>',
    '<%= email_field_tag :reply_to, "support@example.test", placeholder: "Email", autocomplete: "email" %>',
    '<%= telephone_field_tag :contact_phone, "5551234567", class: "phone-input" %>',
    '<%= telephone_field_tag :support_phone, "8005551212", placeholder: "Phone", autocomplete: "tel" %>',
    '<%= url_field_tag :homepage, "https://example.test", class: "url-input" %>',
    '<%= url_field_tag :callback_url, "https://example.test/callback", placeholder: "URL", data: {controller: "url"} %>',
    '<%= number_field_tag :quantity, 3.5, min: "0" %>',
    '<%= number_field_tag :priority, 2.5, min: 0, step: "0.5" %>',
    '<%= range_field_tag :completion, 0.75, max: "1" %>',
    '<%= range_field_tag :progress, 0.5, min: 0, max: 1, step: "0.1" %>',
    '<%= color_field_tag :accent, "#336699", class: "accent-picker" %>',
    '<%= color_field_tag :brand_color, "#ffcc00", data: {controller: "palette"} %>',
    '<%= date_field_tag :due_on, "2026-06-23", class: "date-input" %>',
    '<%= date_field_tag :starts_on, "2026-07-01", min: "2026-01-01", data: {controller: "date"} %>',
    '<%= time_field_tag :starts_at, "09:30", include_seconds: true %>',
    '<%= time_field_tag :ends_at, "17:45", min: "08:00", max: "18:00", step: 60 %>',
    '<%= datetime_field_tag :scheduled_at, "2026-06-23T09:30", class: "datetime-input" %>',
    '<%= datetime_field_tag :published_at, "2026-07-01T17:45", min: "2026-01-01T00:00", data: {controller: "datetime"} %>',
    '<%= month_field_tag :billing_month, "2026-06", class: "month-input" %>',
    '<%= month_field_tag :archive_month, "2026-07", min: "2026-01", data: {controller: "month"} %>',
    '<%= week_field_tag :billing_week, "2026-W26", class: "week-input" %>',
    '<%= week_field_tag :archive_week, "2026-W27", min: "2026-W01", data: {controller: "week"} %>',
    '<%= password_field_tag :admin_password, nil, autocomplete: "current-password" %>',
    '<%= password_field_tag :token, "secret", autocomplete: "one-time-code" %>',
    '<%= hidden_field_tag :return_to, "/todos", data: {tracked: "true"} %>',
    '<%= hidden_field_tag :source, "typed", data: {controller: "source"} %>',
    '<%= file_field_tag :avatar, accept: "image/png" %>',
    '<%= file_field_tag :attachment, multiple: true, direct_upload: true %>',
    '<%= text_area_tag :notes, "Draft note", rows: "4" %>',
    '<%= text_area_tag :comment, "Typed comment", rows: 3 %>',
    '<%= check_box_tag :published, "1", true, class: "published-check" %>',
    '<%= check_box_tag :archived, "yes", false, data: {controller: "archive"} %>',
    '<%= radio_button_tag :visibility, "public", true, class: "visibility-choice" %>',
    '<%= radio_button_tag :visibility, "private", false, data: {controller: "visibility"} %>',
    '<%= image_tag "avatar.png", alt: "Profile avatar", class: "avatar", data: {direct_upload_url: "/rails/active_storage/direct_uploads"} %>',
    '<%= image_tag "badge.png", alt: "RailsHx badge", class: "badge" %>',
    '<%= picture_tag "hero.webp", alt: "Hero image", class: "hero-picture" %>',
    '<%= picture_tag "team.avif", alt: "Team photo", class: "team-picture" %>',
    '<%= favicon_link_tag "favicon.ico", rel: "shortcut icon" %>',
    '<%= favicon_link_tag "touch-icon.png", rel: "apple-touch-icon", type: "image/png" %>',
    '<%= preload_link_tag "application.css", as: "style", type: "text/css" %>',
    '<%= preload_link_tag "app.js", as: "script", crossorigin: "anonymous" %>',
    '<%= javascript_include_tag "dashboard", defer: true, data: {turbo_track: "reload"} %>',
    '<%= javascript_include_tag "analytics", defer: true, type: "module" %>',
    '<%= javascript_tag "window.RailsHxReady = true;", nonce: true %>',
    '<%= javascript_tag "console.log(\'typed helper\');", nonce: true %>',
    '<%= auto_discovery_link_tag :rss, "/feed.xml", title: "Todo feed" %>',
    '<%= auto_discovery_link_tag :atom, "/feed.atom", title: "Atom feed" %>',
    '<%= audio_tag "intro.mp3", controls: true, class: "intro-audio" %>',
    '<%= audio_tag "notify.wav", autoplay: true, controls: true %>',
    '<%= video_tag "demo.mp4", controls: true, poster: "demo.png" %>',
    '<%= video_tag "walkthrough.webm", controls: true, muted: true %>',
    '<%= mail_to "support@example.test", nil, class: "support-link" %>',
    '<%= mail_to "admin@example.test", "Email admin", class: "admin-link" %>',
    '<%= mail_to "ops@example.test", "Ops desk" %>',
    '<%= phone_to "1234567890", nil, class: "phone-link", country_code: "01" %>',
    '<%= phone_to "5551234567", "Call support", class: "support-phone" %>',
    '<%= phone_to "8005551212", "Call sales", country_code: "1" %>',
    '<%= sms_to "5155555785", nil, class: "sms-link", body: "Status update" %>',
    '<%= sms_to "5155555785", "Text support", class: "support-sms" %>',
    '<%= sms_to "8005551212", "Text sales", country_code: "1", body: "Need help" %>',
    '<%= pluralize 2, "task" %>',
    '<%= pluralize 3, "person", "people" %>',
    '<%= simple_format "First line\nSecond line", class: "formatted-copy" %>',
    '<%= simple_format "Inline copy", class: "inline-copy" %>',
    '<%= truncate "Ship the typed template helper surface", length: 12, omission: "..." %>',
    '<%= truncate "Inline helper copy", length: 10, omission: "..." %>',
    '<%= excerpt "This is a very beautiful morning", "very", radius: 3, omission: "..." %>',
    '<%= excerpt "This next thing is an example", "ex", radius: 2, omission: "..." %>',
    '<%= highlight "You searched for: rails", "rails", highlighter: "<em>\\\\1</em>", sanitize: true %>',
    '<%= highlight "You searched for: ruby", "ruby", highlighter: "match: \\\\\\\\1", sanitize: false %>',
    '<%= word_wrap "Once upon a time", line_width: 8, break_sequence: " / " %>',
    '<%= word_wrap "Typed helper output wraps neatly", line_width: 12, break_sequence: " | " %>',
    '<%= sanitize "<b data-safe=\'yes\'>Bold</b><script>bad()</script>", tags: ["b"], attributes: ["data-safe"] %>',
    '<%= sanitize "Inline sanitize copy", tags: ["i"] %>',
    '<%= sanitize_css "width: 100%; background-image: url(\'http://example.test\'); height: 100%;" %>',
    '<%= sanitize_css "color: red; position: absolute;" %>',
    '<%= strip_tags "<b>Bold</b> no more" %>',
    '<%= strip_tags "Inline copy" %>',
    '<%= strip_links "Blog: <a href=\'https://example.test\'>Visit</a>" %>',
    '<%= strip_links "Plain link text" %>',
    '<%= to_sentence ["Draft", "Review", "Ship"], words_connector: ", ", two_words_connector: " or ", last_word_connector: ", or " %>',
    '<%= to_sentence ["One", "Two"], two_words_connector: " plus " %>',
    '<%= escape_once "1 < 2 &amp; 3" %>',
    '<%= escape_once "Accept & Checkout" %>',
    '<%= cdata_section "<hello world>" %>',
    '<%= cdata_section "inline cdata" %>',
    '<%= safe_join ["Draft", "Review", "Ship"], " / " %>',
    '<%= safe_join ["One", "Two"], " + " %>',
    '<%= token_list ["btn", "btn-primary", "is-active"] %>',
    '<%= token_list ["card", "is-selected"] %>',
    '<%= class_names ["btn", "is-disabled"] %>',
    '<%= class_names ["panel", "is-open"] %>',
    '<%= cycle "odd", "even" %>',
    '<%= cycle "red", "green", "blue", name: "colors" %>',
    '<%= current_cycle %>',
    '<%= current_cycle "colors" %>',
    '<% reset_cycle %>',
    '<% reset_cycle "colors" %>',
    '<%= time_ago_in_words Time.now, include_seconds: true %>',
    '<%= time_ago_in_words Time.now, include_seconds: false %>',
    '<%= distance_of_time_in_words Time.now, Time.now, include_seconds: true %>',
    '<%= distance_of_time_in_words Time.now, Time.now, include_seconds: false %>',
    '<%= time_tag Time.now, "Right now", class: "timestamp" %>',
    '<%= time_tag Time.now, "Updated", class: "updated-at", data: {controller: "clock"} %>',
    '<%= number_to_currency 12.5, unit: "$", precision: 2 %>',
    '<%= number_to_currency 99.95, unit: "USD ", precision: 0 %>',
    '<%= number_to_percentage 42.5, precision: 1 %>',
    '<%= number_to_percentage 87.25, precision: 2 %>',
    '<%= number_to_human 1234567.0, precision: 2 %>',
    '<%= number_to_human 987654.0, precision: 3 %>',
    '<%= number_to_human_size 1048576.0, precision: 2 %>',
    '<%= number_to_human_size 1536000.0, precision: 3 %>',
    '<%= number_with_precision 12345.6789, precision: 2, significant: false, delimiter: ",", separator: ".", strip_insignificant_zeros: true %>',
    '<%= number_with_precision 9876.54321, precision: 3, significant: true, delimiter: " ", separator: ",", strip_insignificant_zeros: false %>',
    '<%= number_with_delimiter 1234567.89, delimiter: " ", separator: "," %>',
    '<%= number_with_delimiter 987654.32, delimiter: ".", separator: "," %>',
    '<%= number_to_delimited 1234567.89, delimiter: " ", separator: "," %>',
    '<%= number_to_delimited 987654.32, delimiter: ".", separator: "," %>',
    '<%= number_to_phone "5551234567", area_code: true, delimiter: "-", extension: "9", country_code: 1 %>',
    '<%= number_to_phone "8005551212", area_code: true, delimiter: ".", extension: "42", country_code: 1 %>',
  ]) {
    if (!generated.includes(expected)) {
      console.error(`Checked H.data/H.aria helper fixture missing expected output: ${expected}`);
      process.exit(1);
    }
  }
}

function expectCheckedAttrHelpersFailure() {
  const result = compileCheckedAttrFixture(checkedAttrInvalidSourceDir, checkedAttrInvalidOutputDir, "InvalidCheckedAttrMain", "InvalidCheckedAttrView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_checked_attrs\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidCheckedAttrView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.el(\"div\", [H.aria(\"aria-live\", \"polite\")], []);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid H.aria prefixed suffix compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("expects the suffix only")) {
    console.error("Invalid H.aria suffix failed, but not with the expected checked attribute diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectButtonTagTypeFailure() {
  const result = compileCheckedAttrFixture(buttonTagInvalidSourceDir, buttonTagInvalidOutputDir, "InvalidButtonTagMain", "InvalidButtonTagView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_button_tag\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidButtonTagView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.buttonTag(42, []);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid button_tag content value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid button_tag content failed, but not with the expected String content type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectSubmitTagTypeFailure() {
  const result = compileCheckedAttrFixture(submitTagInvalidSourceDir, submitTagInvalidOutputDir, "InvalidSubmitTagMain", "InvalidSubmitTagView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_submit_tag\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidSubmitTagView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.submitTag(42, []);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid submit_tag value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid submit_tag value failed, but not with the expected String value type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectTextFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(textFieldTagInvalidSourceDir, textFieldTagInvalidOutputDir, "InvalidTextFieldTagMain",
    "InvalidTextFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_text_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidTextFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.textFieldTag(42, null, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid text_field_tag name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid text_field_tag name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectSearchFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(searchFieldTagInvalidSourceDir, searchFieldTagInvalidOutputDir, "InvalidSearchFieldTagMain",
    "InvalidSearchFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_search_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidSearchFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.searchFieldTag(42, null, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid search_field_tag name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid search_field_tag name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectEmailFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(emailFieldTagInvalidSourceDir, emailFieldTagInvalidOutputDir, "InvalidEmailFieldTagMain",
    "InvalidEmailFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_email_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidEmailFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.emailFieldTag(42, null, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid email_field_tag name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid email_field_tag name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectTelephoneFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(telephoneFieldTagInvalidSourceDir, telephoneFieldTagInvalidOutputDir, "InvalidTelephoneFieldTagMain",
    "InvalidTelephoneFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_telephone_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidTelephoneFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.telephoneFieldTag(42, null, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid telephone_field_tag name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid telephone_field_tag name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectUrlFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(urlFieldTagInvalidSourceDir, urlFieldTagInvalidOutputDir, "InvalidUrlFieldTagMain",
    "InvalidUrlFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_url_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidUrlFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.urlFieldTag(42, null, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid url_field_tag name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid url_field_tag name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectNumberFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(numberFieldTagInvalidSourceDir, numberFieldTagInvalidOutputDir, "InvalidNumberFieldTagMain",
    "InvalidNumberFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_number_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidNumberFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.numberFieldTag(\"quantity\", \"many\", []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid number_field_tag value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("String") || !output.includes("Float")) {
    console.error("Invalid number_field_tag value failed, but not with the expected Float value type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectRangeFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(rangeFieldTagInvalidSourceDir, rangeFieldTagInvalidOutputDir, "InvalidRangeFieldTagMain",
    "InvalidRangeFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_range_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidRangeFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.rangeFieldTag(\"completion\", \"half\", []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid range_field_tag value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("String") || !output.includes("Float")) {
    console.error("Invalid range_field_tag value failed, but not with the expected Float value type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectColorFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(colorFieldTagInvalidSourceDir, colorFieldTagInvalidOutputDir, "InvalidColorFieldTagMain",
    "InvalidColorFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_color_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidColorFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.colorFieldTag(\"accent\", 336699, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid color_field_tag value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid color_field_tag value failed, but not with the expected String value type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectDateFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(dateFieldTagInvalidSourceDir, dateFieldTagInvalidOutputDir, "InvalidDateFieldTagMain",
    "InvalidDateFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_date_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidDateFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.dateFieldTag(\"due_on\", 20260623, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid date_field_tag value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid date_field_tag value failed, but not with the expected String value type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectTimeFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(timeFieldTagInvalidSourceDir, timeFieldTagInvalidOutputDir, "InvalidTimeFieldTagMain",
    "InvalidTimeFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_time_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidTimeFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.timeFieldTag(\"starts_at\", 930, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid time_field_tag value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid time_field_tag value failed, but not with the expected String value type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectDatetimeFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(datetimeFieldTagInvalidSourceDir, datetimeFieldTagInvalidOutputDir,
    "InvalidDatetimeFieldTagMain", "InvalidDatetimeFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_datetime_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidDatetimeFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.datetimeFieldTag(\"scheduled_at\", 202606230930, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid datetime_field_tag value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Float") || !output.includes("String")) {
    console.error("Invalid datetime_field_tag value failed, but not with the expected String value type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectMonthFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(monthFieldTagInvalidSourceDir, monthFieldTagInvalidOutputDir, "InvalidMonthFieldTagMain",
    "InvalidMonthFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_month_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidMonthFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.monthFieldTag(\"billing_month\", 202606, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid month_field_tag value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid month_field_tag value failed, but not with the expected String value type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectWeekFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(weekFieldTagInvalidSourceDir, weekFieldTagInvalidOutputDir, "InvalidWeekFieldTagMain",
    "InvalidWeekFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_week_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidWeekFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.weekFieldTag(\"billing_week\", 202626, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid week_field_tag value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid week_field_tag value failed, but not with the expected String value type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectPasswordFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(passwordFieldTagInvalidSourceDir, passwordFieldTagInvalidOutputDir, "InvalidPasswordFieldTagMain",
    "InvalidPasswordFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_password_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidPasswordFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.passwordFieldTag(42, null, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid password_field_tag name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid password_field_tag name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectHiddenFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(hiddenFieldTagInvalidSourceDir, hiddenFieldTagInvalidOutputDir, "InvalidHiddenFieldTagMain",
    "InvalidHiddenFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_hidden_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidHiddenFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.hiddenFieldTag(42, null, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid hidden_field_tag name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid hidden_field_tag name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectFileFieldTagTypeFailure() {
  const result = compileCheckedAttrFixture(fileFieldTagInvalidSourceDir, fileFieldTagInvalidOutputDir, "InvalidFileFieldTagMain",
    "InvalidFileFieldTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_file_field_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidFileFieldTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.fileFieldTag(42, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid file_field_tag name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid file_field_tag name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectTextAreaTagTypeFailure() {
  const result = compileCheckedAttrFixture(textAreaTagInvalidSourceDir, textAreaTagInvalidOutputDir, "InvalidTextAreaTagMain",
    "InvalidTextAreaTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_text_area_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidTextAreaTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.textAreaTag(42, null, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid text_area_tag name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid text_area_tag name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectCheckBoxTagTypeFailure() {
  const result = compileCheckedAttrFixture(checkBoxTagInvalidSourceDir, checkBoxTagInvalidOutputDir, "InvalidCheckBoxTagMain",
    "InvalidCheckBoxTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_check_box_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidCheckBoxTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.checkBoxTag(42, null, null, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid check_box_tag name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid check_box_tag name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectRadioButtonTagTypeFailure() {
  const result = compileCheckedAttrFixture(radioButtonTagInvalidSourceDir, radioButtonTagInvalidOutputDir, "InvalidRadioButtonTagMain",
    "InvalidRadioButtonTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_radio_button_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidRadioButtonTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.radioButtonTag(\"visibility\", 42, null, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid radio_button_tag value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid radio_button_tag value failed, but not with the expected String value type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectFormSelectOptionTypeFailure() {
  const result = compileCheckedAttrFixture(formSelectInvalidSourceDir, formSelectInvalidOutputDir, "InvalidFormSelectMain",
    "InvalidFormSelectView", [
      "package views;",
      "",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_form_select\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidFormSelectView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn <form_with url=\"/users\" scope=\"user\"><select name=\"role\" options=${[{label: \"Member\", value: 42}]} /></form_with>;",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid form select option value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid form select option failed, but not with the expected String option type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectFormEmailFieldTypeFailure() {
  const result = compileCheckedAttrFixture(formEmailFieldInvalidSourceDir, formEmailFieldInvalidOutputDir, "InvalidFormEmailFieldMain",
    "InvalidFormEmailFieldView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_form_email_field\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidFormEmailFieldView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.formWith(\"/users\", \"user\", [], [H.emailField(42, [])]);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid form email_field name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid form email_field name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectFormSearchFieldTypeFailure() {
  const result = compileCheckedAttrFixture(formSearchFieldInvalidSourceDir, formSearchFieldInvalidOutputDir, "InvalidFormSearchFieldMain",
    "InvalidFormSearchFieldView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_form_search_field\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidFormSearchFieldView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.formWith(\"/todos\", \"todo\", [], [H.searchField(42, [])]);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid form search_field name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid form search_field name failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectPictureTagTypeFailure() {
  const result = compileCheckedAttrFixture(pictureTagInvalidSourceDir, pictureTagInvalidOutputDir, "InvalidPictureTagMain", "InvalidPictureTagView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_picture_tag\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidPictureTagView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.pictureTag(42, []);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid picture_tag source value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid picture_tag source failed, but not with the expected String source type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectFaviconLinkTagTypeFailure() {
  const result = compileCheckedAttrFixture(faviconLinkTagInvalidSourceDir, faviconLinkTagInvalidOutputDir, "InvalidFaviconLinkTagMain",
    "InvalidFaviconLinkTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_favicon_link_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidFaviconLinkTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.faviconLinkTag(42, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid favicon_link_tag source value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid favicon_link_tag source failed, but not with the expected String source type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectPreloadLinkTagTypeFailure() {
  const result = compileCheckedAttrFixture(preloadLinkTagInvalidSourceDir, preloadLinkTagInvalidOutputDir, "InvalidPreloadLinkTagMain",
    "InvalidPreloadLinkTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_preload_link_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidPreloadLinkTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.preloadLinkTag(42, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid preload_link_tag source value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid preload_link_tag source failed, but not with the expected String source type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectJavascriptIncludeTagTypeFailure() {
  const result = compileCheckedAttrFixture(javascriptIncludeTagInvalidSourceDir, javascriptIncludeTagInvalidOutputDir,
    "InvalidJavascriptIncludeTagMain", "InvalidJavascriptIncludeTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_javascript_include_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidJavascriptIncludeTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.javascriptIncludeTag(42, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid javascript_include_tag source value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid javascript_include_tag source failed, but not with the expected String source type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectJavascriptTagTypeFailure() {
  const result = compileCheckedAttrFixture(javascriptTagInvalidSourceDir, javascriptTagInvalidOutputDir, "InvalidJavascriptTagMain",
    "InvalidJavascriptTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_javascript_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidJavascriptTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.javascriptTag(42, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid javascript_tag content value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid javascript_tag content failed, but not with the expected String content type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectAutoDiscoveryLinkTagTypeFailure() {
  const result = compileCheckedAttrFixture(autoDiscoveryLinkTagInvalidSourceDir, autoDiscoveryLinkTagInvalidOutputDir,
    "InvalidAutoDiscoveryLinkTagMain", "InvalidAutoDiscoveryLinkTagView", [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_auto_discovery_link_tag\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidAutoDiscoveryLinkTagView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.autoDiscoveryLinkTag(\"rss\", 42, []);",
      "\t}",
      "}",
      "",
    ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid auto_discovery_link_tag URL value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid auto_discovery_link_tag URL failed, but not with the expected String URL type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectAudioTagTypeFailure() {
  const result = compileCheckedAttrFixture(audioTagInvalidSourceDir, audioTagInvalidOutputDir, "InvalidAudioTagMain", "InvalidAudioTagView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_audio_tag\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidAudioTagView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.audioTag(42, []);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid audio_tag source value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid audio_tag source failed, but not with the expected String source type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectVideoTagTypeFailure() {
  const result = compileCheckedAttrFixture(videoTagInvalidSourceDir, videoTagInvalidOutputDir, "InvalidVideoTagMain", "InvalidVideoTagView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_video_tag\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidVideoTagView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.videoTag(42, []);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid video_tag source value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid video_tag source failed, but not with the expected String source type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectPhoneToTypeFailure() {
  const result = compileCheckedAttrFixture(phoneToInvalidSourceDir, phoneToInvalidOutputDir, "InvalidPhoneToMain", "InvalidPhoneToView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_phone_to\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidPhoneToView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.phoneTo(42, null, []);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid phone_to phone value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid phone_to value failed, but not with the expected String phone type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectSmsToTypeFailure() {
  const result = compileCheckedAttrFixture(smsToInvalidSourceDir, smsToInvalidOutputDir, "InvalidSmsToMain", "InvalidSmsToView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_sms_to\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidSmsToView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.smsTo(42, null, []);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid sms_to phone value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid sms_to value failed, but not with the expected String phone type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectExcerptTypeFailure() {
  const result = compileCheckedAttrFixture(excerptInvalidSourceDir, excerptInvalidOutputDir, "InvalidExcerptMain", "InvalidExcerptView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_excerpt\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidExcerptView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.excerpt(\"This is an example\", 42, 5, \"...\");",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid excerpt phrase value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid excerpt value failed, but not with the expected String type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectHighlightTypeFailure() {
  const result = compileCheckedAttrFixture(highlightInvalidSourceDir, highlightInvalidOutputDir, "InvalidHighlightMain", "InvalidHighlightView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_highlight\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidHighlightView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.highlight(\"You searched for: rails\", 42, null, true);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid highlight phrase value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid highlight value failed, but not with the expected String type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectWordWrapTypeFailure() {
  const result = compileCheckedAttrFixture(wordWrapInvalidSourceDir, wordWrapInvalidOutputDir, "InvalidWordWrapMain", "InvalidWordWrapView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_word_wrap\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidWordWrapView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.wordWrap(42, 8, \"\\n\");",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid word_wrap text value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid word_wrap value failed, but not with the expected String type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectSanitizeTypeFailure() {
  const result = compileCheckedAttrFixture(sanitizeInvalidSourceDir, sanitizeInvalidOutputDir, "InvalidSanitizeMain", "InvalidSanitizeView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_sanitize\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidSanitizeView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.sanitize(\"<b>Bold</b>\", [\"b\", 42], null);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid sanitize tag value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid sanitize value failed, but not with the expected String tag type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectSanitizeCssTypeFailure() {
  const result = compileCheckedAttrFixture(sanitizeCssInvalidSourceDir, sanitizeCssInvalidOutputDir, "InvalidSanitizeCssMain", "InvalidSanitizeCssView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_sanitize_css\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidSanitizeCssView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.sanitizeCss(42);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid sanitize_css style value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid sanitize_css value failed, but not with the expected String style type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectStripTagsTypeFailure() {
  const result = compileCheckedAttrFixture(stripTagsInvalidSourceDir, stripTagsInvalidOutputDir, "InvalidStripTagsMain", "InvalidStripTagsView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_strip_tags\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidStripTagsView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.stripTags(42);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid strip_tags html value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid strip_tags value failed, but not with the expected String type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectStripLinksTypeFailure() {
  const result = compileCheckedAttrFixture(stripLinksInvalidSourceDir, stripLinksInvalidOutputDir, "InvalidStripLinksMain", "InvalidStripLinksView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_strip_links\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidStripLinksView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.stripLinks(42);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid strip_links html value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid strip_links value failed, but not with the expected String type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectToSentenceTypeFailure() {
  const result = compileCheckedAttrFixture(toSentenceInvalidSourceDir, toSentenceInvalidOutputDir, "InvalidToSentenceMain", "InvalidToSentenceView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_to_sentence\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidToSentenceView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.toSentence([\"Draft\", 42], null, null, null);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid to_sentence item value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid to_sentence value failed, but not with the expected String item type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectEscapeOnceTypeFailure() {
  const result = compileCheckedAttrFixture(escapeOnceInvalidSourceDir, escapeOnceInvalidOutputDir, "InvalidEscapeOnceMain", "InvalidEscapeOnceView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_escape_once\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidEscapeOnceView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.escapeOnce(42);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid escape_once html value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid escape_once value failed, but not with the expected String type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectCdataSectionTypeFailure() {
  const result = compileCheckedAttrFixture(cdataSectionInvalidSourceDir, cdataSectionInvalidOutputDir, "InvalidCdataSectionMain", "InvalidCdataSectionView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_cdata_section\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidCdataSectionView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.cdataSection(42);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid cdata_section content value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid cdata_section value failed, but not with the expected String type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectSafeJoinTypeFailure() {
  const result = compileCheckedAttrFixture(safeJoinInvalidSourceDir, safeJoinInvalidOutputDir, "InvalidSafeJoinMain", "InvalidSafeJoinView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_safe_join\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidSafeJoinView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.safeJoin([\"Draft\", 42], \" / \");",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid safe_join item value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid safe_join value failed, but not with the expected String item type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectTokenListTypeFailure() {
  const result = compileCheckedAttrFixture(tokenListInvalidSourceDir, tokenListInvalidOutputDir, "InvalidTokenListMain", "InvalidTokenListView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_token_list\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidTokenListView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.tokenList([\"btn\", 42]);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid token_list token value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid token_list value failed, but not with the expected String token type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectClassNamesTypeFailure() {
  const result = compileCheckedAttrFixture(classNamesInvalidSourceDir, classNamesInvalidOutputDir, "InvalidClassNamesMain", "InvalidClassNamesView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_class_names\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidClassNamesView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.classNames([\"btn\", 42]);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid class_names token value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid class_names value failed, but not with the expected String token type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectCycleTypeFailure() {
  const result = compileCheckedAttrFixture(cycleInvalidSourceDir, cycleInvalidOutputDir, "InvalidCycleMain", "InvalidCycleView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_cycle\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidCycleView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.cycle([\"odd\", 42], null);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid cycle value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid cycle value failed, but not with the expected String value type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectCurrentCycleTypeFailure() {
  const result = compileCheckedAttrFixture(
    currentCycleInvalidSourceDir,
    currentCycleInvalidOutputDir,
    "InvalidCurrentCycleMain",
    "InvalidCurrentCycleView",
    [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_current_cycle\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidCurrentCycleView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.currentCycle(42);",
      "\t}",
      "}",
      "",
    ],
    { allowFailure: true },
  );
  if (result.status === 0) {
    console.error("Invalid current_cycle name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid current_cycle value failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectResetCycleTypeFailure() {
  const result = compileCheckedAttrFixture(
    resetCycleInvalidSourceDir,
    resetCycleInvalidOutputDir,
    "InvalidResetCycleMain",
    "InvalidResetCycleView",
    [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_reset_cycle\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidResetCycleView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.resetCycle(42);",
      "\t}",
      "}",
      "",
    ],
    { allowFailure: true },
  );
  if (result.status === 0) {
    console.error("Invalid reset_cycle name compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid reset_cycle value failed, but not with the expected String name type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectTimeAgoInWordsTypeFailure() {
  const result = compileCheckedAttrFixture(timeAgoInvalidSourceDir, timeAgoInvalidOutputDir, "InvalidTimeAgoMain", "InvalidTimeAgoView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_time_ago\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidTimeAgoView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.timeAgoInWords(3600, true);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid time_ago_in_words numeric value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("Date")) {
    console.error("Invalid time_ago_in_words value failed, but not with the expected Date type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectDistanceOfTimeInWordsTypeFailure() {
  const result = compileCheckedAttrFixture(distanceOfTimeInvalidSourceDir, distanceOfTimeInvalidOutputDir, "InvalidDistanceOfTimeMain", "InvalidDistanceOfTimeView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_distance_of_time\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidDistanceOfTimeView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.distanceOfTimeInWords(Date.now(), 3600, true);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid distance_of_time_in_words numeric value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("Date")) {
    console.error("Invalid distance_of_time_in_words value failed, but not with the expected Date type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectTimeTagTypeFailure() {
  const result = compileCheckedAttrFixture(timeTagInvalidSourceDir, timeTagInvalidOutputDir, "InvalidTimeTagMain", "InvalidTimeTagView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_time_tag\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidTimeTagView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.timeTag(\"now\", \"Right now\", []);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid time_tag time value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("String") || !output.includes("Date")) {
    console.error("Invalid time_tag value failed, but not with the expected Date type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectNumberToPhoneTypeFailure() {
  const result = compileCheckedAttrFixture(numberToPhoneInvalidSourceDir, numberToPhoneInvalidOutputDir, "InvalidNumberToPhoneMain", "InvalidNumberToPhoneView", [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/invalid_number_to_phone\")",
    "@:railsTemplateAst(\"render\")",
    "class InvalidNumberToPhoneView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.numberToPhone(5551234, true, \"-\", null, 1);",
    "\t}",
    "}",
    "",
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error("Invalid number_to_phone phone value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("Int") || !output.includes("String")) {
    console.error("Invalid number_to_phone value failed, but not with the expected String type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectNumberToHumanSizeTypeFailure() {
  const result = compileCheckedAttrFixture(
    numberToHumanSizeInvalidSourceDir,
    numberToHumanSizeInvalidOutputDir,
    "InvalidNumberToHumanSizeMain",
    "InvalidNumberToHumanSizeView",
    [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_number_to_human_size\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidNumberToHumanSizeView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.numberToHumanSize(\"large\", 2);",
      "\t}",
      "}",
      "",
    ],
    { allowFailure: true },
  );
  if (result.status === 0) {
    console.error("Invalid number_to_human_size numeric value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("String") || !output.includes("Float")) {
    console.error("Invalid number_to_human_size value failed, but not with the expected Float type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectNumberWithPrecisionTypeFailure() {
  const result = compileCheckedAttrFixture(
    numberWithPrecisionInvalidSourceDir,
    numberWithPrecisionInvalidOutputDir,
    "InvalidNumberWithPrecisionMain",
    "InvalidNumberWithPrecisionView",
    [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_number_with_precision\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidNumberWithPrecisionView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.numberWithPrecision(\"large\", 2, false, null, null, null);",
      "\t}",
      "}",
      "",
    ],
    { allowFailure: true },
  );
  if (result.status === 0) {
    console.error("Invalid number_with_precision numeric value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("String") || !output.includes("Float")) {
    console.error("Invalid number_with_precision value failed, but not with the expected Float type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectNumberWithDelimiterTypeFailure() {
  const result = compileCheckedAttrFixture(
    numberWithDelimiterInvalidSourceDir,
    numberWithDelimiterInvalidOutputDir,
    "InvalidNumberWithDelimiterMain",
    "InvalidNumberWithDelimiterView",
    [
      "package views;",
      "",
      "import rails.action_view.H;",
      "import rails.action_view.HtmlNode;",
      "",
      "@:railsTemplate(\"controllers/todos/invalid_number_with_delimiter\")",
      "@:railsTemplateAst(\"render\")",
      "class InvalidNumberWithDelimiterView {",
      "\tpublic static function render():HtmlNode {",
      "\t\treturn H.numberWithDelimiter(\"large\", null, null);",
      "\t}",
      "}",
      "",
    ],
    { allowFailure: true },
  );
  if (result.status === 0) {
    console.error("Invalid number_with_delimiter numeric value compiled successfully.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes("String") || !output.includes("Float")) {
    console.error("Invalid number_with_delimiter value failed, but not with the expected Float type diagnostic.");
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(1);
  }
}

function expectTypedRouteHelperFailure() {
  mkdirSync(join(typedRouteInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedRouteInvalidSourceDir, "InvalidTypedRouteMain.hx"), [
    "import views.BadTypedRouteView;",
    "",
    "class InvalidTypedRouteMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedRouteView> = BadTypedRouteView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedRouteInvalidSourceDir, "views", "BadTypedRouteView.hx"), [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "import routes.Routes;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_route\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedRouteView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.linkTo(\"Broken\", Routes.missingPath(), []);",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${typedRouteInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      join(exampleDir, "src_haxe"),
      "-cp",
      typedRouteInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedRouteMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid typed route helper compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("missingPath") && !output.includes("has no field")) {
      console.error("Invalid typed route helper failed, but not with the expected typed route error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid typed route helper check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTypedRouteParamFailure() {
  mkdirSync(join(typedRouteParamInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedRouteParamInvalidSourceDir, "InvalidTypedRouteParamMain.hx"), [
    "import views.BadTypedRouteParamView;",
    "",
    "class InvalidTypedRouteParamMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedRouteParamView> = BadTypedRouteParamView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedRouteParamInvalidSourceDir, "views", "BadTypedRouteParamView.hx"), [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "import routes.Routes;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_route_param\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedRouteParamView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.linkTo(\"Broken\", Routes.rootPath({id: 1}), []);",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${typedRouteParamInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      join(exampleDir, "src_haxe"),
      "-cp",
      typedRouteParamInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedRouteParamMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid typed route helper param compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("Too many arguments") && !output.includes("expects no arguments")) {
      console.error("Invalid typed route helper param failed, but not with the expected route arity error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid typed route helper param check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTypedFormFieldRequiresFormFailure() {
  mkdirSync(join(typedFormInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedFormInvalidSourceDir, "InvalidTypedFormMain.hx"), [
    "import views.BadTypedFormView;",
    "",
    "class InvalidTypedFormMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedFormView> = BadTypedFormView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedFormInvalidSourceDir, "views", "BadTypedFormView.hx"), [
    "package views;",
    "",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_form\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedFormView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <text_field name=\"title\" />;",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${typedFormInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      typedFormInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedFormMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid typed form field outside <form_with> compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("Rails form field helpers must be used inside <form_with>")) {
      console.error("Invalid typed form field failed, but not with the expected form context error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid typed form field check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTypedSlotContentRequiresComponentFailure() {
  mkdirSync(join(typedSlotInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedSlotInvalidSourceDir, "InvalidTypedSlotMain.hx"), [
    "import views.BadTypedSlotView;",
    "",
    "class InvalidTypedSlotMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedSlotView> = BadTypedSlotView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedSlotInvalidSourceDir, "views", "BadTypedSlotView.hx"), [
    "package views;",
    "",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Slot;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_slot\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedSlotView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <div>${Slot.content()}</div>;",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${typedSlotInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      typedSlotInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedSlotMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Slot.content() outside HtmlNode.Component compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("Slot.content() may only be used as the matching slot local for HtmlNode.Component")) {
      console.error("Invalid Slot.content() usage failed, but not with the expected typed slot error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid typed slot check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTemplateOfRequiresRailsTemplateFailure() {
  mkdirSync(join(templateRefInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(templateRefInvalidSourceDir, "InvalidTemplateRefMain.hx"), [
    "import views.BadTemplateRefView;",
    "",
    "class InvalidTemplateRefMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTemplateRefView> = BadTemplateRefView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(templateRefInvalidSourceDir, "views", "PlainView.hx"), [
    "package views;",
    "",
    "class PlainView {}",
    "",
  ].join("\n"));
  writeFileSync(join(templateRefInvalidSourceDir, "views", "BadTemplateRefView.hx"), [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Template;",
    "",
    "typedef DummyLocals = {",
    "\tvar title:String;",
    "}",
    "",
    "@:railsTemplate(\"controllers/todos/bad_template_ref\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTemplateRefView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.partial((Template.of(PlainView) : Template<DummyLocals>), {title: \"bad\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${templateRefInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      templateRefInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTemplateRefMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Template.of accepted a class without @:railsTemplate.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("Template.of/layout expects a class annotated with @:railsTemplate")) {
      console.error("Invalid Template.of view failed, but not with the expected template annotation error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid Template.of check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectUnsafeRailsTemplatePathFailure() {
  mkdirSync(join(templatePathInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(templatePathInvalidSourceDir, "InvalidTemplatePathMain.hx"), [
    "import views.BadTemplatePathView;",
    "",
    "class InvalidTemplatePathMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTemplatePathView> = BadTemplatePathView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(templatePathInvalidSourceDir, "views", "BadTemplatePathView.hx"), [
    "package views;",
    "",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"../bad\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTemplatePathView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <div>bad</div>;",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${templatePathInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      templatePathInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTemplatePathMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Unsafe @:railsTemplate path compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("@:railsTemplate path must be a safe Rails template path relative to app/views")) {
      console.error("Unsafe @:railsTemplate path failed, but not with the expected path safety error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid @:railsTemplate path check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectBackslashRailsTemplatePathFailure() {
  mkdirSync(join(templateBackslashPathInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(templateBackslashPathInvalidSourceDir, "InvalidTemplateBackslashPathMain.hx"), [
    "import views.BadTemplateBackslashPathView;",
    "",
    "class InvalidTemplateBackslashPathMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTemplateBackslashPathView> = BadTemplateBackslashPathView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(templateBackslashPathInvalidSourceDir, "views", "BadTemplateBackslashPathView.hx"), [
    "package views;",
    "",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers\\\\todos\\\\bad\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTemplateBackslashPathView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <div>bad</div>;",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${templateBackslashPathInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      templateBackslashPathInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTemplateBackslashPathMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Backslash @:railsTemplate path compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("@:railsTemplate path must be a safe Rails template path relative to app/views")) {
      console.error("Backslash @:railsTemplate path failed, but not with the expected path safety error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid backslash @:railsTemplate path check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectRawLayoutStringFailure() {
  mkdirSync(join(rawLayoutInvalidSourceDir, "controllers"), { recursive: true });
  writeFileSync(join(rawLayoutInvalidSourceDir, "RawLayoutMain.hx"), [
    "import controllers.RawLayoutController;",
    "",
    "class RawLayoutMain {",
    "\tstatic function main() {",
    "\t\tvar controller:RawLayoutController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(rawLayoutInvalidSourceDir, "controllers", "RawLayoutController.hx"), [
    "package controllers;",
    "",
    "import models.Todo;",
    "import rails.action_view.Template;",
    "import rails.macros.ViewMacro;",
    "import views.TodoIndexView;",
    "import views.TodoIndexView.TodoIndexLocals;",
    "",
    "@:railsController",
    "class RawLayoutController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = [];",
    "",
    "\tpublic function index() {",
    "\t\tvar todos = Todo.incomplete();",
    "\t\tViewMacro.renderTemplateWithLayout(this, (Template.of(TodoIndexView) : Template<TodoIndexLocals>), {",
    "\t\t\ttodos: todos,",
    "\t\t\ttodoCount: todos.length,",
    "\t\t\ttypedColumnCount: Todo.typedColumnCount(),",
    "\t\t\tsampleUser: models.User.first()",
    "\t\t}, \"application\");",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${rawLayoutInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      rawLayoutInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "RawLayoutMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Raw string layout compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("String should be rails.action_view.Layout")
      && !output.includes("ViewMacro.renderTemplateWithLayout layout expects Template.layout")) {
      console.error("Raw string layout failed, but not with the expected typed layout diagnostic.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run raw layout string check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectUnknownTypedFormFieldFailure() {
  mkdirSync(join(typedFieldInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedFieldInvalidSourceDir, "InvalidTypedFieldMain.hx"), [
    "import views.BadTypedFieldView;",
    "",
    "class InvalidTypedFieldMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedFieldView> = BadTypedFieldView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedFieldInvalidSourceDir, "views", "BadTypedFieldView.hx"), [
    "package views;",
    "",
    "import models.Todo;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_typed_field\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedFieldView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <form_with url=\"/todos\" scope=${Todo.railsParamKey}><text_field name=${Todo.f.missing} /></form_with>;",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${typedFieldInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      typedFieldInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedFieldMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Unknown typed RailsHx form field compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("has no field missing")) {
      console.error("Unknown typed RailsHx form field failed, but not with the expected missing field error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid typed form field ref check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectMixedModelStrongParamsFailure() {
  mkdirSync(join(typedParamsInvalidSourceDir, "controllers"), { recursive: true });
  writeFileSync(join(typedParamsInvalidSourceDir, "InvalidTypedParamsMain.hx"), [
    "import controllers.BadTypedParamsController;",
    "",
    "class InvalidTypedParamsMain {",
    "\tstatic function main() {",
    "\t\tvar controller:BadTypedParamsController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedParamsInvalidSourceDir, "controllers", "BadTypedParamsController.hx"), [
    "package controllers;",
    "",
    "import models.Todo;",
    "import models.User;",
    "import rails.macros.ParamsMacro;",
    "",
    "@:railsController",
    "class BadTypedParamsController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = [];",
    "",
    "\tpublic function create() {",
    "\t\tParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.title, User.f.name]);",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${typedParamsInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      join(exampleDir, "src_haxe"),
      "-cp",
      typedParamsInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedParamsMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Mixed-model ParamsMacro.requirePermit field refs compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("ParamsMacro.requirePermit field refs must belong to the same model as the typed params root")) {
      console.error("Mixed-model ParamsMacro.requirePermit failed, but not with the expected model-scope error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid mixed-model strong params check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectUnknownStrongParamsFieldFailure() {
  mkdirSync(join(typedParamsUnknownSourceDir, "controllers"), { recursive: true });
  writeFileSync(join(typedParamsUnknownSourceDir, "InvalidUnknownParamsMain.hx"), [
    "import controllers.BadUnknownParamsController;",
    "",
    "class InvalidUnknownParamsMain {",
    "\tstatic function main() {",
    "\t\tvar controller:BadUnknownParamsController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedParamsUnknownSourceDir, "controllers", "BadUnknownParamsController.hx"), [
    "package controllers;",
    "",
    "import models.Todo;",
    "import rails.macros.ParamsMacro;",
    "",
    "@:railsController",
    "class BadUnknownParamsController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = [];",
    "",
    "\tpublic function create() {",
    "\t\tParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.missing]);",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${typedParamsUnknownOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      join(exampleDir, "src_haxe"),
      "-cp",
      typedParamsUnknownSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidUnknownParamsMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Unknown ParamsMacro.requirePermit field ref compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("has no field missing")) {
      console.error("Unknown ParamsMacro.requirePermit field failed, but not with the expected missing field error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid unknown strong params field check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectUnknownRequestParamsFieldFailure() {
  mkdirSync(join(typedRequestParamsUnknownSourceDir, "tests"), { recursive: true });
  writeFileSync(join(typedRequestParamsUnknownSourceDir, "InvalidRequestParamsMain.hx"), [
    "import tests.BadRequestParamsTest;",
    "",
    "class InvalidRequestParamsMain {",
    "\tstatic function main() {",
    "\t\tvar testClass:Class<BadRequestParamsTest> = BadRequestParamsTest;",
    "\t\tSys.println(testClass != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedRequestParamsUnknownSourceDir, "tests", "BadRequestParamsTest.hx"), [
    "package tests;",
    "",
    "import models.Todo;",
    "import rails.test.RequestParams;",
    "",
    "class BadRequestParamsTest {",
    "\tpublic static function build():Dynamic {",
    "\t\treturn RequestParams.model(Todo.railsParamKey, {missing: \"nope\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${typedRequestParamsUnknownOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      join(exampleDir, "src_haxe"),
      "-cp",
      typedRequestParamsUnknownSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidRequestParamsMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Unknown RequestParams.model field compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes('RequestParams.model field "missing" is not a @:railsColumn field on Todo')) {
      console.error("Unknown RequestParams.model field failed, but not with the expected missing field error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid request params field check; no Reflaxe candidate found.");
    process.exit(1);
  }
}
