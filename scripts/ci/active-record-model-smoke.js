#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "active_record_model");
const invalidSourceDir = join(root, "test", ".generated", "active_record_model_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "active_record_model_invalid_out");
const invalidWhereSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_src");
const invalidWhereOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_out");
const invalidWhereTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_type_src");
const invalidWhereTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_type_out");
const invalidWhereNotSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_not_src");
const invalidWhereNotOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_not_out");
const invalidWhereNotTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_not_type_src");
const invalidWhereNotTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_not_type_out");
const invalidWhereInOwnerSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_in_owner_src");
const invalidWhereInOwnerOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_in_owner_out");
const invalidWhereInTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_in_type_src");
const invalidWhereInTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_in_type_out");
const invalidWhereInStringSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_in_string_src");
const invalidWhereInStringOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_in_string_out");
const invalidWhereBetweenOwnerSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_between_owner_src");
const invalidWhereBetweenOwnerOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_between_owner_out");
const invalidWhereBetweenTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_between_type_src");
const invalidWhereBetweenTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_between_type_out");
const invalidWhereBetweenStringSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_between_string_src");
const invalidWhereBetweenStringOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_between_string_out");
const invalidWhereComparisonOwnerSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_comparison_owner_src");
const invalidWhereComparisonOwnerOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_comparison_owner_out");
const invalidWhereComparisonTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_comparison_type_src");
const invalidWhereComparisonTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_comparison_type_out");
const invalidWhereComparisonStringSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_comparison_string_src");
const invalidWhereComparisonStringOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_comparison_string_out");
const invalidOrderStringSourceDir = join(root, "test", ".generated", "active_record_model_invalid_order_string_src");
const invalidOrderStringOutputDir = join(root, "test", ".generated", "active_record_model_invalid_order_string_out");
const invalidExprOrderOwnerSourceDir = join(root, "test", ".generated", "active_record_model_invalid_expr_order_owner_src");
const invalidExprOrderOwnerOutputDir = join(root, "test", ".generated", "active_record_model_invalid_expr_order_owner_out");
const invalidExprLowerTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_expr_lower_type_src");
const invalidExprLowerTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_expr_lower_type_out");
const invalidWhereExprShapeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_expr_shape_src");
const invalidWhereExprShapeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_expr_shape_out");
const invalidWhereExprOwnerSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_expr_owner_src");
const invalidWhereExprOwnerOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_expr_owner_out");
const invalidWhereExprTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_expr_type_src");
const invalidWhereExprTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_expr_type_out");
const invalidFluentExprLowerTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_fluent_expr_lower_type_src");
const invalidFluentExprLowerTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_fluent_expr_lower_type_out");
const invalidFluentWhereExprOwnerSourceDir = join(root, "test", ".generated", "active_record_model_invalid_fluent_where_expr_owner_src");
const invalidFluentWhereExprOwnerOutputDir = join(root, "test", ".generated", "active_record_model_invalid_fluent_where_expr_owner_out");
const invalidFluentWhereExprTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_fluent_where_expr_type_src");
const invalidFluentWhereExprTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_fluent_where_expr_type_out");
const invalidWhereSqlStringSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_sql_string_src");
const invalidWhereSqlStringOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_sql_string_out");
const invalidWhereSqlOwnerSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_sql_owner_src");
const invalidWhereSqlOwnerOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_sql_owner_out");
const invalidOrderSqlKindSourceDir = join(root, "test", ".generated", "active_record_model_invalid_order_sql_kind_src");
const invalidOrderSqlKindOutputDir = join(root, "test", ".generated", "active_record_model_invalid_order_sql_kind_out");
const invalidWhereNullOwnerSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_null_owner_src");
const invalidWhereNullOwnerOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_null_owner_out");
const invalidWhereNotNullTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_not_null_type_src");
const invalidWhereNotNullTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_not_null_type_out");
const invalidRelationWhereSourceDir = join(root, "test", ".generated", "active_record_model_invalid_relation_where_src");
const invalidRelationWhereOutputDir = join(root, "test", ".generated", "active_record_model_invalid_relation_where_out");
const invalidRewhereSourceDir = join(root, "test", ".generated", "active_record_model_invalid_rewhere_src");
const invalidRewhereOutputDir = join(root, "test", ".generated", "active_record_model_invalid_rewhere_out");
const invalidAssignedRelationSourceDir = join(root, "test", ".generated", "active_record_model_invalid_assigned_relation_src");
const invalidAssignedRelationOutputDir = join(root, "test", ".generated", "active_record_model_invalid_assigned_relation_out");
const invalidAssociationSourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_src");
const invalidAssociationOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_out");
const invalidNestedAssociationSourceDir = join(root, "test", ".generated", "active_record_model_invalid_nested_association_src");
const invalidNestedAssociationOutputDir = join(root, "test", ".generated", "active_record_model_invalid_nested_association_out");
const invalidNestedCriteriaFieldSourceDir = join(root, "test", ".generated", "active_record_model_invalid_nested_criteria_field_src");
const invalidNestedCriteriaFieldOutputDir = join(root, "test", ".generated", "active_record_model_invalid_nested_criteria_field_out");
const invalidNestedCriteriaTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_nested_criteria_type_src");
const invalidNestedCriteriaTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_nested_criteria_type_out");
const invalidMissingFkSourceDir = join(root, "test", ".generated", "active_record_model_invalid_missing_fk_src");
const invalidMissingFkOutputDir = join(root, "test", ".generated", "active_record_model_invalid_missing_fk_out");
const invalidFkTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_fk_type_src");
const invalidFkTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_fk_type_out");
const invalidAssociationTargetSourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_target_src");
const invalidAssociationTargetOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_target_out");
const invalidAssociationOptionSourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_option_src");
const invalidAssociationOptionOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_option_out");
const invalidAssociationDependentSourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_dependent_src");
const invalidAssociationDependentOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_dependent_out");
const invalidAssociationForeignKeySourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_foreign_key_src");
const invalidAssociationForeignKeyOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_foreign_key_out");
const invalidAssociationThroughSourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_through_src");
const invalidAssociationThroughOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_through_out");
const invalidAssociationThroughBelongsToSourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_through_belongs_to_src");
const invalidAssociationThroughBelongsToOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_through_belongs_to_out");
const invalidAssociationSourceShapeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_source_shape_src");
const invalidAssociationSourceShapeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_source_shape_out");
const invalidValidationTargetSourceDir = join(root, "test", ".generated", "active_record_model_invalid_validation_target_src");
const invalidValidationTargetOutputDir = join(root, "test", ".generated", "active_record_model_invalid_validation_target_out");
const invalidValidationOptionSourceDir = join(root, "test", ".generated", "active_record_model_invalid_validation_option_src");
const invalidValidationOptionOutputDir = join(root, "test", ".generated", "active_record_model_invalid_validation_option_out");
const invalidValidationShapeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_validation_shape_src");
const invalidValidationShapeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_validation_shape_out");
const invalidValidationTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_validation_type_src");
const invalidValidationTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_validation_type_out");
const invalidEnumShapeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_enum_shape_src");
const invalidEnumShapeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_enum_shape_out");
const invalidEnumValueSourceDir = join(root, "test", ".generated", "active_record_model_invalid_enum_value_src");
const invalidEnumValueOutputDir = join(root, "test", ".generated", "active_record_model_invalid_enum_value_out");
const invalidEnumTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_enum_type_src");
const invalidEnumTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_enum_type_out");
const invalidCallbackStaticSourceDir = join(root, "test", ".generated", "active_record_model_invalid_callback_static_src");
const invalidCallbackStaticOutputDir = join(root, "test", ".generated", "active_record_model_invalid_callback_static_out");
const invalidCallbackArgsSourceDir = join(root, "test", ".generated", "active_record_model_invalid_callback_args_src");
const invalidCallbackArgsOutputDir = join(root, "test", ".generated", "active_record_model_invalid_callback_args_out");
const invalidCallbackNameSourceDir = join(root, "test", ".generated", "active_record_model_invalid_callback_name_src");
const invalidCallbackNameOutputDir = join(root, "test", ".generated", "active_record_model_invalid_callback_name_out");
const invalidCallbackFieldSourceDir = join(root, "test", ".generated", "active_record_model_invalid_callback_field_src");
const invalidCallbackFieldOutputDir = join(root, "test", ".generated", "active_record_model_invalid_callback_field_out");
const invalidFindSourceDir = join(root, "test", ".generated", "active_record_model_invalid_find_src");
const invalidFindOutputDir = join(root, "test", ".generated", "active_record_model_invalid_find_out");
const invalidRelationFindSourceDir = join(root, "test", ".generated", "active_record_model_invalid_relation_find_src");
const invalidRelationFindOutputDir = join(root, "test", ".generated", "active_record_model_invalid_relation_find_out");
const invalidFindBySourceDir = join(root, "test", ".generated", "active_record_model_invalid_find_by_src");
const invalidFindByOutputDir = join(root, "test", ".generated", "active_record_model_invalid_find_by_out");
const invalidExistsSourceDir = join(root, "test", ".generated", "active_record_model_invalid_exists_src");
const invalidExistsOutputDir = join(root, "test", ".generated", "active_record_model_invalid_exists_out");
const invalidOffsetSourceDir = join(root, "test", ".generated", "active_record_model_invalid_offset_src");
const invalidOffsetOutputDir = join(root, "test", ".generated", "active_record_model_invalid_offset_out");
const invalidOrSourceDir = join(root, "test", ".generated", "active_record_model_invalid_or_src");
const invalidOrOutputDir = join(root, "test", ".generated", "active_record_model_invalid_or_out");
const invalidMergeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_merge_src");
const invalidMergeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_merge_out");
const invalidReorderSourceDir = join(root, "test", ".generated", "active_record_model_invalid_reorder_src");
const invalidReorderOutputDir = join(root, "test", ".generated", "active_record_model_invalid_reorder_out");
const invalidSelectFieldSourceDir = join(root, "test", ".generated", "active_record_model_invalid_select_field_src");
const invalidSelectFieldOutputDir = join(root, "test", ".generated", "active_record_model_invalid_select_field_out");
const invalidPluckFieldSourceDir = join(root, "test", ".generated", "active_record_model_invalid_pluck_field_src");
const invalidPluckFieldOutputDir = join(root, "test", ".generated", "active_record_model_invalid_pluck_field_out");
const invalidProjectionFieldSourceDir = join(root, "test", ".generated", "active_record_model_invalid_projection_field_src");
const invalidProjectionFieldOutputDir = join(root, "test", ".generated", "active_record_model_invalid_projection_field_out");
const invalidProjectionEmptySourceDir = join(root, "test", ".generated", "active_record_model_invalid_projection_empty_src");
const invalidProjectionEmptyOutputDir = join(root, "test", ".generated", "active_record_model_invalid_projection_empty_out");
const invalidProjectionGroupOwnerSourceDir = join(root, "test", ".generated", "active_record_model_invalid_projection_group_owner_src");
const invalidProjectionGroupOwnerOutputDir = join(root, "test", ".generated", "active_record_model_invalid_projection_group_owner_out");
const invalidProjectionGroupStringSourceDir = join(root, "test", ".generated", "active_record_model_invalid_projection_group_string_src");
const invalidProjectionGroupStringOutputDir = join(root, "test", ".generated", "active_record_model_invalid_projection_group_string_out");
const invalidProjectionGroupFieldSourceDir = join(root, "test", ".generated", "active_record_model_invalid_projection_group_field_src");
const invalidProjectionGroupFieldOutputDir = join(root, "test", ".generated", "active_record_model_invalid_projection_group_field_out");
const invalidGroupFieldSourceDir = join(root, "test", ".generated", "active_record_model_invalid_group_field_src");
const invalidGroupFieldOutputDir = join(root, "test", ".generated", "active_record_model_invalid_group_field_out");
const invalidGroupUnsupportedSourceDir = join(root, "test", ".generated", "active_record_model_invalid_group_unsupported_src");
const invalidGroupUnsupportedOutputDir = join(root, "test", ".generated", "active_record_model_invalid_group_unsupported_out");
const invalidGroupHavingOwnerSourceDir = join(root, "test", ".generated", "active_record_model_invalid_group_having_owner_src");
const invalidGroupHavingOwnerOutputDir = join(root, "test", ".generated", "active_record_model_invalid_group_having_owner_out");
const invalidGroupHavingStringSourceDir = join(root, "test", ".generated", "active_record_model_invalid_group_having_string_src");
const invalidGroupHavingStringOutputDir = join(root, "test", ".generated", "active_record_model_invalid_group_having_string_out");
const invalidAggregateFieldSourceDir = join(root, "test", ".generated", "active_record_model_invalid_aggregate_field_src");
const invalidAggregateFieldOutputDir = join(root, "test", ".generated", "active_record_model_invalid_aggregate_field_out");
const invalidAggregateNumericSourceDir = join(root, "test", ".generated", "active_record_model_invalid_aggregate_numeric_src");
const invalidAggregateNumericOutputDir = join(root, "test", ".generated", "active_record_model_invalid_aggregate_numeric_out");
const invalidScopeInstanceSourceDir = join(root, "test", ".generated", "active_record_model_invalid_scope_instance_src");
const invalidScopeInstanceOutputDir = join(root, "test", ".generated", "active_record_model_invalid_scope_instance_out");
const invalidDefaultScopeArgsSourceDir = join(root, "test", ".generated", "active_record_model_invalid_default_scope_args_src");
const invalidDefaultScopeArgsOutputDir = join(root, "test", ".generated", "active_record_model_invalid_default_scope_args_out");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
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

rmSync(outputDir, { force: true, recursive: true });
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });
rmSync(invalidWhereSourceDir, { force: true, recursive: true });
rmSync(invalidWhereOutputDir, { force: true, recursive: true });
rmSync(invalidWhereTypeSourceDir, { force: true, recursive: true });
rmSync(invalidWhereTypeOutputDir, { force: true, recursive: true });
rmSync(invalidWhereNotSourceDir, { force: true, recursive: true });
rmSync(invalidWhereNotOutputDir, { force: true, recursive: true });
rmSync(invalidWhereNotTypeSourceDir, { force: true, recursive: true });
rmSync(invalidWhereNotTypeOutputDir, { force: true, recursive: true });
rmSync(invalidWhereInOwnerSourceDir, { force: true, recursive: true });
rmSync(invalidWhereInOwnerOutputDir, { force: true, recursive: true });
rmSync(invalidWhereInTypeSourceDir, { force: true, recursive: true });
rmSync(invalidWhereInTypeOutputDir, { force: true, recursive: true });
rmSync(invalidWhereInStringSourceDir, { force: true, recursive: true });
rmSync(invalidWhereInStringOutputDir, { force: true, recursive: true });
rmSync(invalidWhereBetweenOwnerSourceDir, { force: true, recursive: true });
rmSync(invalidWhereBetweenOwnerOutputDir, { force: true, recursive: true });
rmSync(invalidWhereBetweenTypeSourceDir, { force: true, recursive: true });
rmSync(invalidWhereBetweenTypeOutputDir, { force: true, recursive: true });
rmSync(invalidWhereBetweenStringSourceDir, { force: true, recursive: true });
rmSync(invalidWhereBetweenStringOutputDir, { force: true, recursive: true });
rmSync(invalidWhereComparisonOwnerSourceDir, { force: true, recursive: true });
rmSync(invalidWhereComparisonOwnerOutputDir, { force: true, recursive: true });
rmSync(invalidWhereComparisonTypeSourceDir, { force: true, recursive: true });
rmSync(invalidWhereComparisonTypeOutputDir, { force: true, recursive: true });
rmSync(invalidWhereComparisonStringSourceDir, { force: true, recursive: true });
rmSync(invalidWhereComparisonStringOutputDir, { force: true, recursive: true });
rmSync(invalidOrderStringSourceDir, { force: true, recursive: true });
rmSync(invalidOrderStringOutputDir, { force: true, recursive: true });
rmSync(invalidExprOrderOwnerSourceDir, { force: true, recursive: true });
rmSync(invalidExprOrderOwnerOutputDir, { force: true, recursive: true });
rmSync(invalidExprLowerTypeSourceDir, { force: true, recursive: true });
rmSync(invalidExprLowerTypeOutputDir, { force: true, recursive: true });
rmSync(invalidWhereExprShapeSourceDir, { force: true, recursive: true });
rmSync(invalidWhereExprShapeOutputDir, { force: true, recursive: true });
rmSync(invalidWhereExprOwnerSourceDir, { force: true, recursive: true });
rmSync(invalidWhereExprOwnerOutputDir, { force: true, recursive: true });
rmSync(invalidWhereExprTypeSourceDir, { force: true, recursive: true });
rmSync(invalidWhereExprTypeOutputDir, { force: true, recursive: true });
rmSync(invalidWhereSqlStringSourceDir, { force: true, recursive: true });
rmSync(invalidWhereSqlStringOutputDir, { force: true, recursive: true });
rmSync(invalidWhereSqlOwnerSourceDir, { force: true, recursive: true });
rmSync(invalidWhereSqlOwnerOutputDir, { force: true, recursive: true });
rmSync(invalidOrderSqlKindSourceDir, { force: true, recursive: true });
rmSync(invalidOrderSqlKindOutputDir, { force: true, recursive: true });
rmSync(invalidWhereNullOwnerSourceDir, { force: true, recursive: true });
rmSync(invalidWhereNullOwnerOutputDir, { force: true, recursive: true });
rmSync(invalidWhereNotNullTypeSourceDir, { force: true, recursive: true });
rmSync(invalidWhereNotNullTypeOutputDir, { force: true, recursive: true });
rmSync(invalidRelationWhereSourceDir, { force: true, recursive: true });
rmSync(invalidRelationWhereOutputDir, { force: true, recursive: true });
rmSync(invalidRewhereSourceDir, { force: true, recursive: true });
rmSync(invalidRewhereOutputDir, { force: true, recursive: true });
rmSync(invalidAssignedRelationSourceDir, { force: true, recursive: true });
rmSync(invalidAssignedRelationOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationSourceDir, { force: true, recursive: true });
rmSync(invalidAssociationOutputDir, { force: true, recursive: true });
rmSync(invalidNestedAssociationSourceDir, { force: true, recursive: true });
rmSync(invalidNestedAssociationOutputDir, { force: true, recursive: true });
rmSync(invalidNestedCriteriaFieldSourceDir, { force: true, recursive: true });
rmSync(invalidNestedCriteriaFieldOutputDir, { force: true, recursive: true });
rmSync(invalidNestedCriteriaTypeSourceDir, { force: true, recursive: true });
rmSync(invalidNestedCriteriaTypeOutputDir, { force: true, recursive: true });
rmSync(invalidMissingFkSourceDir, { force: true, recursive: true });
rmSync(invalidMissingFkOutputDir, { force: true, recursive: true });
rmSync(invalidFkTypeSourceDir, { force: true, recursive: true });
rmSync(invalidFkTypeOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationTargetSourceDir, { force: true, recursive: true });
rmSync(invalidAssociationTargetOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationOptionSourceDir, { force: true, recursive: true });
rmSync(invalidAssociationOptionOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationDependentSourceDir, { force: true, recursive: true });
rmSync(invalidAssociationDependentOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationForeignKeySourceDir, { force: true, recursive: true });
rmSync(invalidAssociationForeignKeyOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationThroughSourceDir, { force: true, recursive: true });
rmSync(invalidAssociationThroughOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationThroughBelongsToSourceDir, { force: true, recursive: true });
rmSync(invalidAssociationThroughBelongsToOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationSourceShapeSourceDir, { force: true, recursive: true });
rmSync(invalidAssociationSourceShapeOutputDir, { force: true, recursive: true });
rmSync(invalidValidationTargetSourceDir, { force: true, recursive: true });
rmSync(invalidValidationTargetOutputDir, { force: true, recursive: true });
rmSync(invalidValidationOptionSourceDir, { force: true, recursive: true });
rmSync(invalidValidationOptionOutputDir, { force: true, recursive: true });
rmSync(invalidValidationShapeSourceDir, { force: true, recursive: true });
rmSync(invalidValidationShapeOutputDir, { force: true, recursive: true });
rmSync(invalidValidationTypeSourceDir, { force: true, recursive: true });
rmSync(invalidValidationTypeOutputDir, { force: true, recursive: true });
rmSync(invalidEnumShapeSourceDir, { force: true, recursive: true });
rmSync(invalidEnumShapeOutputDir, { force: true, recursive: true });
rmSync(invalidEnumValueSourceDir, { force: true, recursive: true });
rmSync(invalidEnumValueOutputDir, { force: true, recursive: true });
rmSync(invalidEnumTypeSourceDir, { force: true, recursive: true });
rmSync(invalidEnumTypeOutputDir, { force: true, recursive: true });
rmSync(invalidCallbackStaticSourceDir, { force: true, recursive: true });
rmSync(invalidCallbackStaticOutputDir, { force: true, recursive: true });
rmSync(invalidCallbackArgsSourceDir, { force: true, recursive: true });
rmSync(invalidCallbackArgsOutputDir, { force: true, recursive: true });
rmSync(invalidCallbackNameSourceDir, { force: true, recursive: true });
rmSync(invalidCallbackNameOutputDir, { force: true, recursive: true });
rmSync(invalidCallbackFieldSourceDir, { force: true, recursive: true });
rmSync(invalidCallbackFieldOutputDir, { force: true, recursive: true });
rmSync(invalidFindSourceDir, { force: true, recursive: true });
rmSync(invalidFindOutputDir, { force: true, recursive: true });
rmSync(invalidRelationFindSourceDir, { force: true, recursive: true });
rmSync(invalidRelationFindOutputDir, { force: true, recursive: true });
rmSync(invalidFindBySourceDir, { force: true, recursive: true });
rmSync(invalidFindByOutputDir, { force: true, recursive: true });
rmSync(invalidExistsSourceDir, { force: true, recursive: true });
rmSync(invalidExistsOutputDir, { force: true, recursive: true });
rmSync(invalidOffsetSourceDir, { force: true, recursive: true });
rmSync(invalidOffsetOutputDir, { force: true, recursive: true });
rmSync(invalidOrSourceDir, { force: true, recursive: true });
rmSync(invalidOrOutputDir, { force: true, recursive: true });
rmSync(invalidMergeSourceDir, { force: true, recursive: true });
rmSync(invalidMergeOutputDir, { force: true, recursive: true });
rmSync(invalidReorderSourceDir, { force: true, recursive: true });
rmSync(invalidReorderOutputDir, { force: true, recursive: true });
rmSync(invalidSelectFieldSourceDir, { force: true, recursive: true });
rmSync(invalidSelectFieldOutputDir, { force: true, recursive: true });
rmSync(invalidPluckFieldSourceDir, { force: true, recursive: true });
rmSync(invalidPluckFieldOutputDir, { force: true, recursive: true });
rmSync(invalidProjectionFieldSourceDir, { force: true, recursive: true });
rmSync(invalidProjectionFieldOutputDir, { force: true, recursive: true });
rmSync(invalidProjectionEmptySourceDir, { force: true, recursive: true });
rmSync(invalidProjectionEmptyOutputDir, { force: true, recursive: true });
rmSync(invalidProjectionGroupOwnerSourceDir, { force: true, recursive: true });
rmSync(invalidProjectionGroupOwnerOutputDir, { force: true, recursive: true });
rmSync(invalidProjectionGroupStringSourceDir, { force: true, recursive: true });
rmSync(invalidProjectionGroupStringOutputDir, { force: true, recursive: true });
rmSync(invalidProjectionGroupFieldSourceDir, { force: true, recursive: true });
rmSync(invalidProjectionGroupFieldOutputDir, { force: true, recursive: true });
rmSync(invalidGroupFieldSourceDir, { force: true, recursive: true });
rmSync(invalidGroupFieldOutputDir, { force: true, recursive: true });
rmSync(invalidGroupUnsupportedSourceDir, { force: true, recursive: true });
rmSync(invalidGroupUnsupportedOutputDir, { force: true, recursive: true });
rmSync(invalidGroupHavingOwnerSourceDir, { force: true, recursive: true });
rmSync(invalidGroupHavingOwnerOutputDir, { force: true, recursive: true });
rmSync(invalidGroupHavingStringSourceDir, { force: true, recursive: true });
rmSync(invalidGroupHavingStringOutputDir, { force: true, recursive: true });
rmSync(invalidAggregateFieldSourceDir, { force: true, recursive: true });
rmSync(invalidAggregateFieldOutputDir, { force: true, recursive: true });
rmSync(invalidAggregateNumericSourceDir, { force: true, recursive: true });
rmSync(invalidAggregateNumericOutputDir, { force: true, recursive: true });
rmSync(invalidScopeInstanceSourceDir, { force: true, recursive: true });
rmSync(invalidScopeInstanceOutputDir, { force: true, recursive: true });
rmSync(invalidDefaultScopeArgsSourceDir, { force: true, recursive: true });
rmSync(invalidDefaultScopeArgsOutputDir, { force: true, recursive: true });

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile active_record_model through Reflaxe.");
  process.exit(1);
}

for (const file of [
  "app/haxe_gen/models/todo.rb",
  "app/haxe_gen/models/user.rb",
  "app/haxe_gen/models/audit_log.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected ActiveRecord output file missing: ${fullPath}`);
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
  "{name: :completed, haxe_name: \"completed\", ruby_name: \"completed\", haxe_type: \"Bool\", rails_type: :boolean, nullable: false, default: false, primary_key: false, index: false, unique: false, db_type: nil}",
  "{name: :status, haxe_name: \"status\", ruby_name: \"status\", haxe_type: \"String\", rails_type: :string, nullable: false, default: \"open\", primary_key: false, index: false, unique: false, db_type: nil}",
  "{name: :notes, haxe_name: \"notes\", ruby_name: \"notes\", haxe_type: \"String\", rails_type: :text, nullable: true, default: nil, primary_key: false, index: false, unique: false, db_type: :text}",
  "{name: :external_id, haxe_name: \"externalId\", ruby_name: \"external_id\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: false, unique: true, db_type: nil}",
  "{name: :user_id, haxe_name: \"userId\", ruby_name: \"user_id\", haxe_type: \"Int\", rails_type: :integer, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  'belongs_to :user, optional: false, foreign_key: "user_id", inverse_of: :todos',
  'enum :status, {open: "open", done: "done"}',
  "# haxe column id: Int",
  "# haxe column title: String",
  "# haxe column completed: Bool",
  "# haxe column status: String",
  "# haxe column notes: Null",
  "# haxe column external_id: String",
  "# haxe column user_id: Int",
  "scope :incomplete, -> { where(completed: false) }",
  "scope :with_status, ->(status__hx0) { where(status: status__hx0) }",
  "default_scope -> { order(title: :asc) }",
  "validates :title, presence: true, length: {minimum: 3}",
  "validates :external_id, presence: true, uniqueness: true",
  'validates :status, inclusion: {within: ["open", "done"]}',
  "before_validation :normalize_title",
  "after_commit :publish_lifecycle_event",
  "def normalize_title()",
  "def publish_lifecycle_event()",
]) {
  if (!todoRuby.includes(expected)) {
    console.error(`ActiveRecord model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const userRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "user.rb"), "utf8");
for (const expected of [
  "class User < ::ApplicationRecord",
  'self.table_name = "users"',
  "def self.__hx_rails_schema()",
  'table_name: "users"',
  "timestamps: true",
  "{name: :id, haxe_name: \"id\", ruby_name: \"id\", haxe_type: \"Int\", rails_type: :bigint, nullable: false, default: nil, primary_key: true, index: false, unique: false, db_type: :bigint}",
  "{name: :name, haxe_name: \"name\", ruby_name: \"name\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "has_many :todos, dependent: :destroy, inverse_of: :user",
  "has_many :todo_owners, through: :todos, source: :user",
  "# haxe column id: Int",
  "# haxe column name: String",
]) {
  if (!userRuby.includes(expected)) {
    console.error(`ActiveRecord user model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

for (const unexpected of ["def self.where", "def self.create"]) {
  if (todoRuby.includes(unexpected)) {
    console.error(`Typed interop stub should not be emitted into model Ruby: ${unexpected}`);
    process.exit(1);
  }
}

for (const unexpected of ["def self.incomplete()", "def self.with_status("]) {
  if (todoRuby.includes(unexpected)) {
    console.error(`Rails scope should be emitted as a scope macro, not a static method: ${unexpected}`);
    process.exit(1);
  }
}

const auditLogRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "audit_log.rb"), "utf8");
for (const expected of [
  "class AuditLog < ::ApplicationRecord",
  'self.table_name = "audit_logs"',
  "def self.__hx_rails_schema()",
  'table_name: "audit_logs"',
  "timestamps: false",
  "{name: :event_count, haxe_name: \"eventCount\", ruby_name: \"event_count\", haxe_type: \"Int\", rails_type: :integer, nullable: false, default: 0, primary_key: false, index: false, unique: false, db_type: nil}",
]) {
  if (!auditLogRuby.includes(expected)) {
    console.error(`ActiveRecord inferred model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const mainRuby = readFileSync(join(outputDir, "app", "haxe_gen", "main.rb"), "utf8");
for (const expected of [
  'Models::Todo.includes(:user).where(title: "ship", status: "open").where(completed: false).joins(:user).order(title: :asc).limit(10)',
  'Models::Todo.includes({user: :todos}).where(status: "open")',
  'Models::Todo.preload({user: :todos}).limit(2)',
  'Models::Todo.where(status: "open").eager_load({user: :todos}).limit(2)',
  'Models::Todo.joins(:user).where(user: {name: "owner"}).limit(3)',
  'Models::Todo.joins(:user).find_by(user: {name: "owner"})',
  'Models::Todo.joins(:user).exists?(user: {id: 1})',
  "Models::Todo.incomplete().includes(:user).limit(5)",
  'Models::Todo.with_status("open").order(title: :asc).limit(4)',
  'Models::User.includes(:todos).joins(:todos).where(name: "owner")',
  'Models::Todo.create(title: "ship", user_id: 1)',
  "Models::AuditLog.where(event_count: 1).order(event_count: :desc)",
  "Models::Todo.find(1)",
  'Models::Todo.find_by(external_id: "ship-1")',
  'Models::Todo.where(title: "ship").find_by(completed: false)',
  'Models::Todo.where(title: "assigned").order(title: :asc).limit(5)',
  'Models::Todo.all().where(status: "open").order(title: :asc).limit(3)',
  'Models::Todo.distinct().where(status: "open").order(title: :asc)',
  'Models::Todo.where.not(status: "done").order(title: :asc).limit(8)',
  '.where.not(status: "done").limit(2)',
  'Models::Todo.where(status: ["open", "done"]).order(title: :asc).limit(9)',
  '.where.not(status: ["archived"]).limit(2)',
  "Models::Todo.where(id: 1..10).order(id: :asc)",
  ".where.not(id: 1..10).limit(2)",
  "Models::Todo.where(Models::Todo.arel_table[:id].gt(1)).order(id: :asc)",
  ".where.not(Models::Todo.arel_table[:id].lteq(10)).limit(2)",
  "Models::Todo.order(Models::Todo.arel_table[:title].lower.asc).limit(3)",
  'Models::Todo.where(Models::Todo.arel_table[:title].lower.eq("ship")).limit(2)',
  'assigned__hx',
  '.where.not(Models::Todo.arel_table[:title].lower.eq("ship")).limit(2)',
  "Models::Todo.where(Models::Todo.arel_table[:id].gt(1)).limit(2)",
  "Models::Todo.where(\"status <> 'archived'\").limit(2)",
  'assigned__hx',
  ".where.not(\"status = 'done'\").limit(2)",
  'Models::Todo.order("LOWER(title) ASC").limit(2)',
  "Models::Todo.where(notes: nil).limit(3)",
  ".where.not(notes: nil).limit(2)",
  '.distinct().limit(2)',
  'Models::Todo.none().where(status: "open")',
  'assigned__hx',
  '.none().limit(1)',
  'Models::Todo.reverse_order().where(status: "open").limit(2)',
  'assigned__hx',
  '.reverse_order().limit(2)',
  'Models::Todo.readonly().where(status: "open").limit(2)',
  'assigned__hx',
  '.readonly().limit(2)',
  'Models::Todo.lock().where(status: "open").limit(1)',
  'assigned__hx',
  '.lock("FOR UPDATE").first()',
  'Models::Todo.where(status: "open").lock("FOR UPDATE NOWAIT").first()',
  'Models::Todo.where(status: "open").or(Models::Todo.where(status: "done")).order(title: :asc)',
  'Models::Todo.where(status: "open").merge(Models::Todo.where(completed: false)).limit(7)',
  'Models::Todo.select(:title).where(status: "open")',
  'assigned__hx',
  '.select(:id).limit(2)',
  'assigned__hx',
  '.reorder(id: :desc)',
  'Models::Todo.reorder(title: :desc).limit(4)',
  'Models::Todo.order(title: :asc, id: :desc).limit(6)',
  'assigned__hx',
  '.reorder(id: :desc, title: :asc)',
  'assigned__hx',
  'rewhere(status: "done")',
  'Models::Todo.rewhere(completed: true).limit(1)',
  'Models::Todo.where(status: "open").offset(20).limit(10)',
  'Models::Todo.offset(5).where(completed: false)',
  'Models::Todo.exists?(external_id: "assigned-1")',
  'assigned__hx',
  'exists?(status: "open")',
  'Models::Todo.where(status: "open").count()',
  'Models::Todo.count()',
  'assigned__hx',
  '.find(1)',
  'assigned__hx',
  'find_by(external_id: "assigned-1")',
  "first__hx",
  ".first()",
  "last__hx",
  "Models::Todo.last()",
  "relation_last__hx",
  ".last()",
  "Models::Todo.pluck(:title)",
  "assigned__hx",
  ".pluck(:id)",
  'HXRuby.active_record_projection(Models::Todo.where(status: "open").pluck(:id, :title), ["id", "title"])',
  'HXRuby.active_record_projection(Models::Todo.pluck(:id, :external_id), ["id", "externalId"])',
  'HXRuby.active_record_projection(Models::Todo.where(status: "open").group(:status).pluck(:status, Models::Todo.arel_table[:id].count, Models::Todo.arel_table[:user_id].sum, Models::Todo.arel_table[:user_id].average, Models::Todo.arel_table[:id].minimum, Models::Todo.arel_table[:title].maximum), ["status", "todoCount", "userIdSum", "averageUserId", "minId", "maxTitle"])',
  'HXRuby.active_record_group_count(Models::Todo.where(status: "open").group(:status).count(), :string)',
  'HXRuby.active_record_group_count(Models::Todo.where(status: "open").group(:status).having(Models::Todo.arel_table[:id].count.gt(1)).count(), :string)',
  "HXRuby.active_record_group_count(Models::Todo.group(:user_id).count(), :int)",
  "HXRuby.active_record_group_count(Models::AuditLog.where(event_count: 1).group(:event_count).count(), :int)",
  "Models::Todo.minimum(:id)",
  "Models::Todo.maximum(:title)",
  "assigned__hx",
  ".maximum(:id)",
  "Models::Todo.sum(:user_id)",
  "Models::Todo.average(:user_id)",
  "assigned__hx",
  ".sum(:user_id)",
  "assigned__hx",
  ".average(:user_id)",
  'Models::Todo.transaction() { Models::Todo.create(title: "inside transaction", user_id: 1) }',
  'Models::Todo.transaction(requires_new: true, isolation: :serializable) { Models::Todo.where(status: "open").lock("FOR SHARE").count() }',
]) {
  if (!mainRuby.includes(expected)) {
    console.error(`ActiveRecord call shape missing from main.rb: ${expected}`);
    process.exit(1);
  }
}

const queryGuide = readFileSync(join(root, "docs", "railshx-query-guide.md"), "utf8");
for (const expected of [
  "RailsHx Typed ActiveRecord Query Guide",
  "Todo.where({",
  "whereNot({status",
  "whereIn(Todo.f.status",
  "whereNotIn(Todo.f.status",
  "whereBetween(Todo.f.id",
  "whereNotBetween(Todo.f.id",
  "whereGt(Todo.f.id",
  "whereNotLte(Todo.f.id",
  "whereNull(Todo.f.notes",
  "whereNotNull(Todo.f.notes",
  "rewhere({status",
  "Todo.f.title.asc()",
  "Todo.a.user",
  "Association.nested(",
  ".preload(",
  ".eagerLoad(",
  "where({user:",
  "Models::Todo.where.not(status:",
  "Models::Todo.where(status: [",
  "Models::Todo.where(id: 1..10)",
  "Models::Todo.where(Models::Todo.arel_table[:id].gt(1))",
  "Todo.f.title.lower().eq(\"ship\")",
  "Todo.where(Todo.f.id.gt(1))",
  "Todo.f.id.count().gt(1)",
  "whereSql(Sql.unsafeWhere",
  "orderSql(Sql.unsafeOrder",
  "Models::Todo.where(notes: nil)",
  "var allOpen = Todo.all()",
  "Todo.distinct()",
  "Todo.none()",
  "Todo.reverseOrder()",
  "Todo.readOnly()",
  "Todo.lock()",
  "Lock.forUpdate()",
  "Todo.transaction(function()",
  "TransactionIsolation.serializable()",
  "@:railsScope",
  "@:railsDefaultScope",
  "scope :with_status",
  ".or(Todo.where({status",
  ".merge(Todo.where({completed",
  "select(Todo.f.title)",
  "reorder(Todo.f.id.desc())",
  "findBy({externalId",
  ".find(1)",
  "exists({externalId",
  ".count()",
  ".last()",
  "pluck(Todo.f.title)",
  "Projection.pluck(",
  "Projection.group(",
  "Group.count(",
  "Group.countHaving(",
  "minimum(Todo.f.id)",
  ".offset(",
  ".toArray()",
  "Models::Todo.incomplete().includes(:user).order(title: :asc).offset(20).limit(10).to_a()",
]) {
  if (!queryGuide.includes(expected)) {
    console.error(`RailsHx query guide missing expected content: ${expected}`);
    process.exit(1);
  }
}

const exampleReadme = readFileSync(join(root, "examples", "active_record_model", "README.md"), "utf8");
for (const expected of [
  "ActiveRecord Model And Query Example",
  "npm run test:active-record-model",
  "Todo.associations.user",
  "Association.nested(Todo.a.user, User.a.todos)",
  "where({user: {name:",
  "Todo.whereNot({status",
  "Todo.whereIn(Todo.f.status",
  "Todo.whereNotIn(Todo.f.status",
  "Todo.whereBetween(Todo.f.id",
  "Todo.whereNotBetween(Todo.f.id",
  "Todo.whereGt(Todo.f.id",
  "Todo.whereNotLte(Todo.f.id",
  "Todo.where(Todo.f.title.lower().eq(\"ship\"))",
  "Todo.f.id.count().gt(1)",
  "Todo.whereNull(Todo.f.notes",
  "Todo.whereNotNull(Todo.f.notes",
  "Todo.rewhere({completed: true})",
  "Todo.whereNot({status",
  "Models::Todo.where.not(status:",
  "whereNull(Todo.f.notes)",
  "var allOpen = Todo",
  ".distinct()",
  "Todo.none()",
  "Todo.reverseOrder()",
  "Todo.readOnly()",
  "Todo.lock()",
  "Lock.forUpdate()",
  "Todo.transaction(function()",
  "TransactionIsolation.serializable()",
  ".or(Todo.where({status",
  ".merge(Todo.where({completed",
  "Todo.select(Todo.f.title)",
  "Todo.reorder(Todo.f.title.desc())",
  "Order.many([Todo.f.title.asc(), Todo.f.id.desc()])",
  "Todo.incomplete().includes(Todo.a.user)",
  "Todo.withStatus(\"open\")",
  "@:railsScope",
  "@:railsDefaultScope",
  "AuditLog.where({eventCount: 1})",
  "Todo.where({status: \"open\"}).offset(20).limit(10)",
  "Todo.exists({externalId",
  "assigned.find(1)",
  "Todo.count()",
  "Todo.last()",
  "Todo.pluck(Todo.f.title)",
  "Projection.pluck(Todo.where",
  "Projection.group(Todo.where",
  "Group.count(Todo.where",
  "Group.countHaving(Todo.where",
  "Todo.minimum(Todo.f.id)",
  "Todo.includes(User.a.todos)",
]) {
  if (!exampleReadme.includes(expected)) {
    console.error(`ActiveRecord example README missing expected content: ${expected}`);
    process.exit(1);
  }
}

expectInvalidColumnDefaultFailure();
expectInvalidWhereFieldFailure();
expectInvalidWhereValueTypeFailure();
expectInvalidWhereNotFieldFailure();
expectInvalidWhereNotValueTypeFailure();
expectInvalidWhereInOwnerFailure();
expectInvalidWhereInValueTypeFailure();
expectInvalidWhereInStringFieldFailure();
expectInvalidWhereBetweenOwnerFailure();
expectInvalidWhereBetweenValueTypeFailure();
expectInvalidWhereBetweenStringFieldFailure();
expectInvalidWhereComparisonOwnerFailure();
expectInvalidWhereComparisonValueTypeFailure();
expectInvalidWhereComparisonStringFieldFailure();
expectInvalidOrderStringFailure();
expectInvalidExprOrderOwnerFailure();
expectInvalidExprLowerValueTypeFailure();
expectInvalidWhereExprShapeFailure();
expectInvalidWhereExprOwnerFailure();
expectInvalidWhereExprValueTypeFailure();
expectInvalidFluentExprLowerValueTypeFailure();
expectInvalidFluentWhereExprOwnerFailure();
expectInvalidFluentWhereExprValueTypeFailure();
expectInvalidWhereSqlStringFailure();
expectInvalidWhereSqlOwnerFailure();
expectInvalidOrderSqlKindFailure();
expectInvalidWhereNullOwnerFailure();
expectInvalidWhereNotNullValueTypeFailure();
expectInvalidRelationWhereFieldFailure();
expectInvalidRewhereFieldFailure();
expectInvalidAssignedRelationFieldFailure();
expectInvalidAssociationOwnerFailure();
expectInvalidNestedAssociationOwnerFailure();
expectInvalidNestedCriteriaFieldFailure();
expectInvalidNestedCriteriaTypeFailure();
expectInvalidMissingBelongsToForeignKeyFailure();
expectInvalidBelongsToForeignKeyTypeFailure();
expectInvalidAssociationTargetFailure();
expectInvalidAssociationOptionFailure();
expectInvalidAssociationDependentFailure();
expectInvalidAssociationForeignKeyFailure();
expectInvalidAssociationThroughFailure();
expectInvalidAssociationThroughBelongsToFailure();
expectInvalidAssociationSourceShapeFailure();
expectInvalidValidationTargetFailure();
expectInvalidValidationOptionFailure();
expectInvalidValidationShapeFailure();
expectInvalidValidationTypeFailure();
expectInvalidEnumShapeFailure();
expectInvalidEnumValueFailure();
expectInvalidEnumTypeFailure();
expectInvalidCallbackStaticFailure();
expectInvalidCallbackArgsFailure();
expectInvalidCallbackNameFailure();
expectInvalidCallbackFieldFailure();
expectInvalidFindValueTypeFailure();
expectInvalidRelationFindValueTypeFailure();
expectInvalidFindByFieldFailure();
expectInvalidExistsFieldFailure();
expectInvalidOffsetValueTypeFailure();
expectInvalidOrOwnerFailure();
expectInvalidMergeOwnerFailure();
expectInvalidReorderOwnerFailure();
expectInvalidSelectFieldOwnerFailure();
expectInvalidPluckFieldOwnerFailure();
expectInvalidProjectionFieldOwnerFailure();
expectInvalidProjectionEmptySpecFailure();
expectInvalidProjectionGroupOwnerFailure();
expectInvalidProjectionGroupStringFailure();
expectInvalidProjectionGroupFieldFailure();
expectInvalidGroupFieldOwnerFailure();
expectInvalidGroupUnsupportedFieldFailure();
expectInvalidGroupHavingOwnerFailure();
expectInvalidGroupHavingStringFailure();
expectInvalidAggregateFieldOwnerFailure();
expectInvalidAggregateNumericFieldFailure();
expectInvalidScopeInstanceFailure();
expectInvalidDefaultScopeArgsFailure();

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
      join(root, "examples", "active_record_model"),
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

function expectInvalidWhereFieldFailure() {
  mkdirSync(invalidWhereSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.where({missing: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereSourceDir,
    invalidWhereOutputDir,
    "Invalid ActiveRecord where field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidExistsFieldFailure() {
  mkdirSync(invalidExistsSourceDir, { recursive: true });
  writeFileSync(join(invalidExistsSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.exists({missing: \"nope\"});",
    "\t\tSys.println(bad);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidExistsSourceDir,
    invalidExistsOutputDir,
    "Invalid ActiveRecord exists field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidOffsetValueTypeFailure() {
  mkdirSync(invalidOffsetSourceDir, { recursive: true });
  writeFileSync(join(invalidOffsetSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.where({status: \"open\"}).offset(\"not an int\");",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidOffsetSourceDir,
    invalidOffsetOutputDir,
    "Invalid ActiveRecord offset value type compiled successfully.",
    "String should be Int"
  );
}

function expectInvalidOrOwnerFailure() {
  mkdirSync(invalidOrSourceDir, { recursive: true });
  writeFileSync(join(invalidOrSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.where({status: \"open\"}).or(User.where({name: \"owner\"}));",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidOrSourceDir,
    invalidOrOutputDir,
    "Invalid ActiveRecord or owner compiled successfully.",
    "Relation<models.User"
  );
}

function expectInvalidMergeOwnerFailure() {
  mkdirSync(invalidMergeSourceDir, { recursive: true });
  writeFileSync(join(invalidMergeSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.where({status: \"open\"}).merge(User.where({name: \"owner\"}));",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidMergeSourceDir,
    invalidMergeOutputDir,
    "Invalid ActiveRecord merge owner compiled successfully.",
    "Relation<models.User"
  );
}

function expectInvalidReorderOwnerFailure() {
  mkdirSync(invalidReorderSourceDir, { recursive: true });
  writeFileSync(join(invalidReorderSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "import rails.active_record.Order;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.reorder(Order.many([Todo.f.title.asc(), User.f.name.asc()]));",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidReorderSourceDir,
    invalidReorderOutputDir,
    "Invalid ActiveRecord reorder owner compiled successfully.",
    "Order<models.User"
  );
}

function expectInvalidSelectFieldOwnerFailure() {
  mkdirSync(invalidSelectFieldSourceDir, { recursive: true });
  writeFileSync(join(invalidSelectFieldSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.select(User.f.name);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidSelectFieldSourceDir,
    invalidSelectFieldOutputDir,
    "Invalid ActiveRecord select field owner compiled successfully.",
    "Field<models.User"
  );
}

function expectInvalidPluckFieldOwnerFailure() {
  mkdirSync(invalidPluckFieldSourceDir, { recursive: true });
  writeFileSync(join(invalidPluckFieldSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.pluck(User.f.name);",
    "\t\tSys.println(bad.length);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidPluckFieldSourceDir,
    invalidPluckFieldOutputDir,
    "Invalid ActiveRecord pluck field owner compiled successfully.",
    "Field<models.User"
  );
}

function expectInvalidProjectionFieldOwnerFailure() {
  mkdirSync(invalidProjectionFieldSourceDir, { recursive: true });
  writeFileSync(join(invalidProjectionFieldSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "import rails.active_record.Projection;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Projection.pluck(Todo, {id: Todo.f.id, name: User.f.name});",
    "\t\tSys.println(bad.length);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidProjectionFieldSourceDir,
    invalidProjectionFieldOutputDir,
    "Invalid ActiveRecord projection field owner compiled successfully.",
    "Projection.pluck field refs must belong to the same model as the source"
  );
}

function expectInvalidProjectionEmptySpecFailure() {
  mkdirSync(invalidProjectionEmptySourceDir, { recursive: true });
  writeFileSync(join(invalidProjectionEmptySourceDir, "Main.hx"), [
    "import models.Todo;",
    "import rails.active_record.Projection;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Projection.pluck(Todo, {});",
    "\t\tSys.println(bad.length);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidProjectionEmptySourceDir,
    invalidProjectionEmptyOutputDir,
    "Invalid ActiveRecord empty projection spec compiled successfully.",
    "Projection.pluck spec must be a non-empty object literal"
  );
}

function expectInvalidProjectionGroupOwnerFailure() {
  mkdirSync(invalidProjectionGroupOwnerSourceDir, { recursive: true });
  writeFileSync(join(invalidProjectionGroupOwnerSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "import rails.active_record.Aggregate;",
    "import rails.active_record.Projection;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Projection.group(Todo, Todo.f.status, {status: Todo.f.status, userCount: Aggregate.count(User.f.id)});",
    "\t\tSys.println(bad.length);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidProjectionGroupOwnerSourceDir,
    invalidProjectionGroupOwnerOutputDir,
    "Invalid ActiveRecord grouped projection owner compiled successfully.",
    "Projection.group specs must belong to the same model as the source"
  );
}

function expectInvalidProjectionGroupStringFailure() {
  mkdirSync(invalidProjectionGroupStringSourceDir, { recursive: true });
  writeFileSync(join(invalidProjectionGroupStringSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import rails.active_record.Projection;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Projection.group(Todo, Todo.f.status, {status: Todo.f.status, todoCount: \"COUNT(*)\"});",
    "\t\tSys.println(bad.length);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidProjectionGroupStringSourceDir,
    invalidProjectionGroupStringOutputDir,
    "Invalid ActiveRecord grouped projection string aggregate compiled successfully.",
    "Projection.group specs must use generated RailsHx field refs or typed aggregate expressions"
  );
}

function expectInvalidProjectionGroupFieldFailure() {
  mkdirSync(invalidProjectionGroupFieldSourceDir, { recursive: true });
  writeFileSync(join(invalidProjectionGroupFieldSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import rails.active_record.Aggregate;",
    "import rails.active_record.Projection;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Projection.group(Todo, Todo.f.status, {title: Todo.f.title, todoCount: Aggregate.count(Todo.f.id)});",
    "\t\tSys.println(bad.length);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidProjectionGroupFieldSourceDir,
    invalidProjectionGroupFieldOutputDir,
    "Invalid ActiveRecord grouped projection non-grouped field compiled successfully.",
    "Projection.group field specs must use the grouped field"
  );
}

function expectInvalidGroupFieldOwnerFailure() {
  mkdirSync(invalidGroupFieldSourceDir, { recursive: true });
  writeFileSync(join(invalidGroupFieldSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "import rails.active_record.Group;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Group.count(Todo, User.f.name);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidGroupFieldSourceDir,
    invalidGroupFieldOutputDir,
    "Invalid ActiveRecord group field owner compiled successfully.",
    "Group.count field refs must belong to the same model as the source"
  );
}

function expectInvalidGroupUnsupportedFieldFailure() {
  mkdirSync(invalidGroupUnsupportedSourceDir, { recursive: true });
  writeFileSync(join(invalidGroupUnsupportedSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import rails.active_record.Group;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Group.count(Todo, Todo.f.completed);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidGroupUnsupportedSourceDir,
    invalidGroupUnsupportedOutputDir,
    "Invalid ActiveRecord unsupported group field compiled successfully.",
    "Group.count only supports String and Int fields in v1"
  );
}

function expectInvalidGroupHavingOwnerFailure() {
  mkdirSync(invalidGroupHavingOwnerSourceDir, { recursive: true });
  writeFileSync(join(invalidGroupHavingOwnerSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "import rails.active_record.Aggregate;",
    "import rails.active_record.Group;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Group.countHaving(Todo, Todo.f.status, Aggregate.count(User.f.id).gt(1));",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidGroupHavingOwnerSourceDir,
    invalidGroupHavingOwnerOutputDir,
    "Invalid ActiveRecord group having predicate owner compiled successfully.",
    "Group.countHaving predicate refs must belong to the same model as the source"
  );
}

function expectInvalidGroupHavingStringFailure() {
  mkdirSync(invalidGroupHavingStringSourceDir, { recursive: true });
  writeFileSync(join(invalidGroupHavingStringSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import rails.active_record.Group;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Group.countHaving(Todo, Todo.f.status, \"COUNT(*) > 1\");",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidGroupHavingStringSourceDir,
    invalidGroupHavingStringOutputDir,
    "Invalid ActiveRecord group having string predicate compiled successfully.",
    "Group.countHaving predicate must be a typed Predicate"
  );
}

function expectInvalidAggregateFieldOwnerFailure() {
  mkdirSync(invalidAggregateFieldSourceDir, { recursive: true });
  writeFileSync(join(invalidAggregateFieldSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.maximum(User.f.name);",
    "\t\tSys.println(bad);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAggregateFieldSourceDir,
    invalidAggregateFieldOutputDir,
    "Invalid ActiveRecord aggregate field owner compiled successfully.",
    "Field<models.User"
  );
}

function expectInvalidAggregateNumericFieldFailure() {
  mkdirSync(invalidAggregateNumericSourceDir, { recursive: true });
  writeFileSync(join(invalidAggregateNumericSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.sum(Todo.f.title);",
    "\t\tSys.println(bad);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAggregateNumericSourceDir,
    invalidAggregateNumericOutputDir,
    "Invalid ActiveRecord numeric aggregate field compiled successfully.",
    "String should be Int"
  );
}

function expectInvalidWhereValueTypeFailure() {
  mkdirSync(invalidWhereTypeSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereTypeSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.where({completed: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereTypeSourceDir,
    invalidWhereTypeOutputDir,
    "Invalid ActiveRecord where value type compiled successfully.",
    "String should be Null<Bool>"
  );
}

function expectInvalidWhereNotFieldFailure() {
  mkdirSync(invalidWhereNotSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereNotSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereNot({missing: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereNotSourceDir,
    invalidWhereNotOutputDir,
    "Invalid ActiveRecord whereNot field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidWhereNotValueTypeFailure() {
  mkdirSync(invalidWhereNotTypeSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereNotTypeSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereNot({completed: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereNotTypeSourceDir,
    invalidWhereNotTypeOutputDir,
    "Invalid ActiveRecord whereNot value type compiled successfully.",
    "String should be Null<Bool>"
  );
}

function expectInvalidWhereInOwnerFailure() {
  mkdirSync(invalidWhereInOwnerSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereInOwnerSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereIn(User.f.name, [\"owner\"]);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereInOwnerSourceDir,
    invalidWhereInOwnerOutputDir,
    "Invalid ActiveRecord whereIn field owner compiled successfully.",
    "models.User should be models.Todo"
  );
}

function expectInvalidWhereInValueTypeFailure() {
  mkdirSync(invalidWhereInTypeSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereInTypeSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereIn(Todo.f.id, [\"nope\"]);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereInTypeSourceDir,
    invalidWhereInTypeOutputDir,
    "Invalid ActiveRecord whereIn value type compiled successfully.",
    "String should be Int"
  );
}

function expectInvalidWhereInStringFieldFailure() {
  mkdirSync(invalidWhereInStringSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereInStringSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereIn(\"status\", [\"open\"]);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereInStringSourceDir,
    invalidWhereInStringOutputDir,
    "Invalid ActiveRecord whereIn string field compiled successfully.",
    "String should be rails.active_record.Field<models.Todo"
  );
}

function expectInvalidWhereBetweenOwnerFailure() {
  mkdirSync(invalidWhereBetweenOwnerSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereBetweenOwnerSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereBetween(User.f.id, 1, 10);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereBetweenOwnerSourceDir,
    invalidWhereBetweenOwnerOutputDir,
    "Invalid ActiveRecord whereBetween field owner compiled successfully.",
    "models.User should be models.Todo"
  );
}

function expectInvalidWhereBetweenValueTypeFailure() {
  mkdirSync(invalidWhereBetweenTypeSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereBetweenTypeSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereBetween(Todo.f.id, \"low\", \"high\");",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereBetweenTypeSourceDir,
    invalidWhereBetweenTypeOutputDir,
    "Invalid ActiveRecord whereBetween value type compiled successfully.",
    "String should be Int"
  );
}

function expectInvalidWhereBetweenStringFieldFailure() {
  mkdirSync(invalidWhereBetweenStringSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereBetweenStringSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereBetween(\"id\", 1, 10);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereBetweenStringSourceDir,
    invalidWhereBetweenStringOutputDir,
    "Invalid ActiveRecord whereBetween string field compiled successfully.",
    "String should be rails.active_record.Field<models.Todo"
  );
}

function expectInvalidWhereComparisonOwnerFailure() {
  mkdirSync(invalidWhereComparisonOwnerSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereComparisonOwnerSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereGt(User.f.id, 1);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereComparisonOwnerSourceDir,
    invalidWhereComparisonOwnerOutputDir,
    "Invalid ActiveRecord comparison field owner compiled successfully.",
    "models.User should be models.Todo"
  );
}

function expectInvalidWhereComparisonValueTypeFailure() {
  mkdirSync(invalidWhereComparisonTypeSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereComparisonTypeSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereLte(Todo.f.id, \"ten\");",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereComparisonTypeSourceDir,
    invalidWhereComparisonTypeOutputDir,
    "Invalid ActiveRecord comparison value type compiled successfully.",
    "String should be Int"
  );
}

function expectInvalidWhereComparisonStringFieldFailure() {
	mkdirSync(invalidWhereComparisonStringSourceDir, { recursive: true });
	writeFileSync(join(invalidWhereComparisonStringSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereGt(\"id\", 1);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereComparisonStringSourceDir,
    invalidWhereComparisonStringOutputDir,
    "Invalid ActiveRecord comparison string field compiled successfully.",
		"String should be rails.active_record.Field<models.Todo"
	);
}

function expectInvalidOrderStringFailure() {
	mkdirSync(invalidOrderStringSourceDir, { recursive: true });
	writeFileSync(join(invalidOrderStringSourceDir, "Main.hx"), [
		"import models.Todo;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar bad = Todo.order(\"LOWER(title) ASC\");",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidOrderStringSourceDir,
		invalidOrderStringOutputDir,
		"Invalid ActiveRecord raw string order compiled successfully.",
		"String should be rails.active_record.Order<models.Todo>"
	);
}

function expectInvalidExprOrderOwnerFailure() {
	mkdirSync(invalidExprOrderOwnerSourceDir, { recursive: true });
	writeFileSync(join(invalidExprOrderOwnerSourceDir, "Main.hx"), [
		"import models.Todo;",
		"import models.User;",
		"import rails.active_record.Expr;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar bad = Todo.order(Expr.lower(User.f.name).asc());",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidExprOrderOwnerSourceDir,
		invalidExprOrderOwnerOutputDir,
		"Invalid ActiveRecord Expr order owner compiled successfully.",
		"models.User should be models.Todo"
	);
}

function expectInvalidExprLowerValueTypeFailure() {
	mkdirSync(invalidExprLowerTypeSourceDir, { recursive: true });
	writeFileSync(join(invalidExprLowerTypeSourceDir, "Main.hx"), [
		"import models.Todo;",
		"import rails.active_record.Expr;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar bad = Todo.order(Expr.lower(Todo.f.id).asc());",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidExprLowerTypeSourceDir,
		invalidExprLowerTypeOutputDir,
		"Invalid ActiveRecord Expr.lower non-string field compiled successfully.",
		"Int should be String"
	);
}

function expectInvalidWhereExprShapeFailure() {
	mkdirSync(invalidWhereExprShapeSourceDir, { recursive: true });
	writeFileSync(join(invalidWhereExprShapeSourceDir, "Main.hx"), [
		"import models.Todo;",
		"import rails.active_record.Expr;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar bad = Todo.whereExpr(Expr.field(Todo.f.title));",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidWhereExprShapeSourceDir,
		invalidWhereExprShapeOutputDir,
		"Invalid ActiveRecord whereExpr non-predicate compiled successfully.",
		"Expr<models.Todo, String> should be rails.active_record.Predicate<models.Todo>"
	);
}

function expectInvalidWhereExprOwnerFailure() {
	mkdirSync(invalidWhereExprOwnerSourceDir, { recursive: true });
	writeFileSync(join(invalidWhereExprOwnerSourceDir, "Main.hx"), [
		"import models.Todo;",
		"import models.User;",
		"import rails.active_record.Expr;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar bad = Todo.whereExpr(Expr.lower(User.f.name).eq(\"owner\"));",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidWhereExprOwnerSourceDir,
		invalidWhereExprOwnerOutputDir,
		"Invalid ActiveRecord whereExpr owner compiled successfully.",
		"models.User should be models.Todo"
	);
}

function expectInvalidWhereExprValueTypeFailure() {
	mkdirSync(invalidWhereExprTypeSourceDir, { recursive: true });
	writeFileSync(join(invalidWhereExprTypeSourceDir, "Main.hx"), [
		"import models.Todo;",
		"import rails.active_record.Expr;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar bad = Todo.whereExpr(Expr.field(Todo.f.id).gt(\"one\"));",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidWhereExprTypeSourceDir,
		invalidWhereExprTypeOutputDir,
		"Invalid ActiveRecord whereExpr value type compiled successfully.",
		"String should be Int"
	);
}

function expectInvalidFluentExprLowerValueTypeFailure() {
	mkdirSync(invalidFluentExprLowerTypeSourceDir, { recursive: true });
	writeFileSync(join(invalidFluentExprLowerTypeSourceDir, "Main.hx"), [
		"import models.Todo;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar bad = Todo.order(Todo.f.id.lower().asc());",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidFluentExprLowerTypeSourceDir,
		invalidFluentExprLowerTypeOutputDir,
		"Invalid ActiveRecord fluent lower non-string field compiled successfully.",
		"has no field lower"
	);
}

function expectInvalidFluentWhereExprOwnerFailure() {
	mkdirSync(invalidFluentWhereExprOwnerSourceDir, { recursive: true });
	writeFileSync(join(invalidFluentWhereExprOwnerSourceDir, "Main.hx"), [
		"import models.Todo;",
		"import models.User;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar bad = Todo.where(User.f.name.eq(\"owner\"));",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidFluentWhereExprOwnerSourceDir,
		invalidFluentWhereExprOwnerOutputDir,
		"Invalid ActiveRecord fluent where predicate owner compiled successfully.",
		"models.User should be models.Todo"
	);
}

function expectInvalidFluentWhereExprValueTypeFailure() {
	mkdirSync(invalidFluentWhereExprTypeSourceDir, { recursive: true });
	writeFileSync(join(invalidFluentWhereExprTypeSourceDir, "Main.hx"), [
		"import models.Todo;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar bad = Todo.where(Todo.f.id.gt(\"one\"));",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidFluentWhereExprTypeSourceDir,
		invalidFluentWhereExprTypeOutputDir,
		"Invalid ActiveRecord fluent where predicate value type compiled successfully.",
		"String should be Int"
	);
}

function expectInvalidWhereSqlStringFailure() {
	mkdirSync(invalidWhereSqlStringSourceDir, { recursive: true });
	writeFileSync(join(invalidWhereSqlStringSourceDir, "Main.hx"), [
		"import models.Todo;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar bad = Todo.whereSql(\"status = 'open'\");",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidWhereSqlStringSourceDir,
		invalidWhereSqlStringOutputDir,
		"Invalid ActiveRecord whereSql raw string compiled successfully.",
		"String should be rails.active_record.Sql<models.Todo"
	);
}

function expectInvalidWhereSqlOwnerFailure() {
	mkdirSync(invalidWhereSqlOwnerSourceDir, { recursive: true });
	writeFileSync(join(invalidWhereSqlOwnerSourceDir, "Main.hx"), [
		"import models.Todo;",
		"import models.User;",
		"import rails.active_record.Sql;",
		"import rails.active_record.SqlWhere;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar userFragment:Sql<User, SqlWhere> = Sql.unsafeWhere(\"name = 'owner'\");",
		"\t\tvar bad = Todo.whereSql(userFragment);",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidWhereSqlOwnerSourceDir,
		invalidWhereSqlOwnerOutputDir,
		"Invalid ActiveRecord whereSql owner compiled successfully.",
		"models.User should be models.Todo"
	);
}

function expectInvalidOrderSqlKindFailure() {
	mkdirSync(invalidOrderSqlKindSourceDir, { recursive: true });
	writeFileSync(join(invalidOrderSqlKindSourceDir, "Main.hx"), [
		"import models.Todo;",
		"import rails.active_record.Sql;",
		"",
		"class Main {",
		"\tstatic function main() {",
		"\t\tvar bad = Todo.orderSql(Sql.unsafeWhere(\"status = 'open'\"));",
		"\t\tSys.println(bad == null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	expectInvalidCompile(
		invalidOrderSqlKindSourceDir,
		invalidOrderSqlKindOutputDir,
		"Invalid ActiveRecord orderSql where-fragment kind compiled successfully.",
		"SqlWhere should be rails.active_record.SqlOrder"
	);
}

function expectInvalidWhereNullOwnerFailure() {
	mkdirSync(invalidWhereNullOwnerSourceDir, { recursive: true });
	writeFileSync(join(invalidWhereNullOwnerSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereNull(User.f.name);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereNullOwnerSourceDir,
    invalidWhereNullOwnerOutputDir,
    "Invalid ActiveRecord whereNull field owner compiled successfully.",
    "Field<models.User, String> should be rails.active_record.NullableField<models.Todo"
  );
}

function expectInvalidWhereNotNullValueTypeFailure() {
  mkdirSync(invalidWhereNotNullTypeSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereNotNullTypeSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.whereNotNull(Todo.f.status);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereNotNullTypeSourceDir,
    invalidWhereNotNullTypeOutputDir,
    "Invalid ActiveRecord whereNotNull non-nullable field compiled successfully.",
    "Field<models.Todo, String> should be rails.active_record.NullableField<models.Todo"
  );
}

function expectInvalidRelationWhereFieldFailure() {
  mkdirSync(invalidRelationWhereSourceDir, { recursive: true });
  writeFileSync(join(invalidRelationWhereSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.where({title: \"ship\"}).where({missing: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidRelationWhereSourceDir,
    invalidRelationWhereOutputDir,
    "Invalid ActiveRecord relation where field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidRewhereFieldFailure() {
  mkdirSync(invalidRewhereSourceDir, { recursive: true });
  writeFileSync(join(invalidRewhereSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.where({title: \"ship\"}).rewhere({missing: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidRewhereSourceDir,
    invalidRewhereOutputDir,
    "Invalid ActiveRecord rewhere field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidAssignedRelationFieldFailure() {
  mkdirSync(invalidAssignedRelationSourceDir, { recursive: true });
  writeFileSync(join(invalidAssignedRelationSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar relation = Todo.where({title: \"ship\"}).order(Todo.f.title.asc()).limit(10);",
    "\t\tvar bad = relation.where({missing: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssignedRelationSourceDir,
    invalidAssignedRelationOutputDir,
    "Invalid assigned ActiveRecord relation where field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidAssociationOwnerFailure() {
  mkdirSync(invalidAssociationSourceDir, { recursive: true });
  writeFileSync(join(invalidAssociationSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.includes(User.a.todos);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationSourceDir,
    invalidAssociationOutputDir,
    "Invalid ActiveRecord association owner compiled successfully.",
    "Association<models.User"
  );
}

function expectInvalidNestedAssociationOwnerFailure() {
  mkdirSync(invalidNestedAssociationSourceDir, { recursive: true });
  writeFileSync(join(invalidNestedAssociationSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "import rails.active_record.Association;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.includes(Association.nested(Todo.a.user, Todo.a.user));",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidNestedAssociationSourceDir,
    invalidNestedAssociationOutputDir,
    "Invalid ActiveRecord nested association owner compiled successfully.",
    "Association<models.Todo"
  );
}

function expectInvalidNestedCriteriaFieldFailure() {
  mkdirSync(invalidNestedCriteriaFieldSourceDir, { recursive: true });
  writeFileSync(join(invalidNestedCriteriaFieldSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.joins(Todo.a.user).where({user: {missing: \"nope\"}});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidNestedCriteriaFieldSourceDir,
    invalidNestedCriteriaFieldOutputDir,
    "Invalid ActiveRecord nested criteria field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidNestedCriteriaTypeFailure() {
  mkdirSync(invalidNestedCriteriaTypeSourceDir, { recursive: true });
  writeFileSync(join(invalidNestedCriteriaTypeSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.joins(Todo.a.user).where({user: {id: \"nope\"}});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidNestedCriteriaTypeSourceDir,
    invalidNestedCriteriaTypeOutputDir,
    "Invalid ActiveRecord nested criteria value type compiled successfully.",
    "String should be Null<Int>"
  );
}

function expectInvalidMissingBelongsToForeignKeyFailure() {
  mkdirSync(join(invalidMissingFkSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidMissingFkSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo.associations.user == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidMissingFkSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "import models.User;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:belongsTo public var user:rails.ActiveRecord.BelongsTo<User>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidMissingFkSourceDir,
    invalidMissingFkOutputDir,
    "Invalid belongsTo without foreign key compiled successfully.",
    "@:belongsTo field user requires a @:railsColumn foreign key named userId"
  );
}

function expectInvalidBelongsToForeignKeyTypeFailure() {
  mkdirSync(join(invalidFkTypeSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidFkTypeSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo.associations.user == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidFkTypeSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "import models.User;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var userId:String;",
    "\t@:belongsTo public var user:rails.ActiveRecord.BelongsTo<User>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidFkTypeSourceDir,
    invalidFkTypeOutputDir,
    "Invalid belongsTo foreign key type compiled successfully.",
    "@:belongsTo foreign key userId must be Int"
  );
}

function expectInvalidAssociationTargetFailure() {
  mkdirSync(join(invalidAssociationTargetSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidAssociationTargetSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo.associations.owner == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationTargetSourceDir, "invalid", "PlainOwner.hx"), [
    "package invalid;",
    "",
    "class PlainOwner {}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationTargetSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var ownerId:Int;",
    "\t@:belongsTo public var owner:rails.ActiveRecord.BelongsTo<PlainOwner>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationTargetSourceDir,
    invalidAssociationTargetOutputDir,
    "Invalid association target compiled successfully.",
    ":belongsTo target invalid.PlainOwner must be a @:railsModel class"
  );
}

function expectInvalidAssociationOptionFailure() {
  mkdirSync(join(invalidAssociationOptionSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidAssociationOptionSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo.associations.user == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationOptionSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "import models.User;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var userId:Int;",
    "\t@:belongsTo({magic: true}) public var user:rails.ActiveRecord.BelongsTo<User>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationOptionSourceDir,
    invalidAssociationOptionOutputDir,
    "Invalid association option compiled successfully.",
    "@:association unknown option magic"
  );
}

function expectInvalidAssociationDependentFailure() {
  mkdirSync(join(invalidAssociationDependentSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidAssociationDependentSourceDir, "Main.hx"), [
    "import invalid.BadUser;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadUser.associations.todos == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationDependentSourceDir, "invalid", "BadUser.hx"), [
    "package invalid;",
    "",
    "import models.Todo;",
    "",
    "@:railsModel(\"bad_users\")",
    "class BadUser extends rails.active_record.Base<BadUser> {",
    "\t@:hasMany({dependent: \"explode\"}) public var todos:rails.ActiveRecord.HasMany<Todo>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationDependentSourceDir,
    invalidAssociationDependentOutputDir,
    "Invalid association dependent value compiled successfully.",
    "@:association option dependent has unsupported value explode"
  );
}

function expectInvalidAssociationForeignKeyFailure() {
  mkdirSync(join(invalidAssociationForeignKeySourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidAssociationForeignKeySourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo.associations.user == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationForeignKeySourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "import models.User;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var userId:Int;",
    "\t@:belongsTo({foreignKey: \"ownerId\"}) public var user:rails.ActiveRecord.BelongsTo<User>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationForeignKeySourceDir,
    invalidAssociationForeignKeyOutputDir,
    "Invalid association foreign key compiled successfully.",
    "@:belongsTo field user requires a @:railsColumn foreign key named ownerId"
  );
}

function expectInvalidAssociationThroughFailure() {
  mkdirSync(join(invalidAssociationThroughSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidAssociationThroughSourceDir, "Main.hx"), [
    "import invalid.BadUser;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadUser.associations.todoOwners == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationThroughSourceDir, "invalid", "BadUser.hx"), [
    "package invalid;",
    "",
    "import models.Todo;",
    "import models.User;",
    "",
    "@:railsModel(\"bad_users\")",
    "class BadUser extends rails.active_record.Base<BadUser> {",
    "\t@:hasMany({through: \"missing\", source: \"user\"}) public var todoOwners:rails.ActiveRecord.HasMany<User>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationThroughSourceDir,
    invalidAssociationThroughOutputDir,
    "Invalid association through target compiled successfully.",
    "@:association through option on todoOwners must reference a model association named missing"
  );
}

function expectInvalidAssociationThroughBelongsToFailure() {
  mkdirSync(join(invalidAssociationThroughBelongsToSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidAssociationThroughBelongsToSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo.associations.user == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationThroughBelongsToSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "import models.User;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var userId:Int;",
    "\t@:belongsTo({through: \"todos\"}) public var user:rails.ActiveRecord.BelongsTo<User>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationThroughBelongsToSourceDir,
    invalidAssociationThroughBelongsToOutputDir,
    "Invalid belongsTo through option compiled successfully.",
    "@:association option through is not valid for @:belongsTo"
  );
}

function expectInvalidAssociationSourceShapeFailure() {
  mkdirSync(join(invalidAssociationSourceShapeSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidAssociationSourceShapeSourceDir, "Main.hx"), [
    "import invalid.BadUser;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadUser.associations.todoOwners == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationSourceShapeSourceDir, "invalid", "BadUser.hx"), [
    "package invalid;",
    "",
    "import models.Todo;",
    "import models.User;",
    "",
    "@:railsModel(\"bad_users\")",
    "class BadUser extends rails.active_record.Base<BadUser> {",
    "\t@:hasMany public var todos:rails.ActiveRecord.HasMany<Todo>;",
    "\t@:hasMany({through: \"todos\", source: true}) public var todoOwners:rails.ActiveRecord.HasMany<User>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationSourceShapeSourceDir,
    invalidAssociationSourceShapeOutputDir,
    "Invalid association source shape compiled successfully.",
    "@:association option source must be a String literal"
  );
}

function expectInvalidValidationTargetFailure() {
  mkdirSync(join(invalidValidationTargetSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidValidationTargetSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidValidationTargetSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var title:String;",
    "\t@:validates({presence: true})",
    "\tpublic var missingValidation:rails.ActiveRecord.Validation<String>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidValidationTargetSourceDir,
    invalidValidationTargetOutputDir,
    "Invalid validation target compiled successfully.",
    "@:validates target missing must match a @:railsColumn field"
  );
}

function expectInvalidValidationOptionFailure() {
  mkdirSync(join(invalidValidationOptionSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidValidationOptionSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidValidationOptionSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var title:String;",
    "\t@:validates({present: true})",
    "\tpublic var titleValidation:rails.ActiveRecord.Validation<String>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidValidationOptionSourceDir,
    invalidValidationOptionOutputDir,
    "Invalid validation option compiled successfully.",
    "@:validates unknown option present"
  );
}

function expectInvalidValidationShapeFailure() {
  mkdirSync(join(invalidValidationShapeSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidValidationShapeSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidValidationShapeSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var title:String;",
    "\t@:validates({length: true})",
    "\tpublic var titleValidation:rails.ActiveRecord.Validation<String>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidValidationShapeSourceDir,
    invalidValidationShapeOutputDir,
    "Invalid validation option shape compiled successfully.",
    "@:validates option length must be an options object"
  );
}

function expectInvalidValidationTypeFailure() {
  mkdirSync(join(invalidValidationTypeSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidValidationTypeSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidValidationTypeSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var title:String;",
    "\t@:validates({presence: true})",
    "\tpublic var titleValidation:rails.ActiveRecord.Validation<Int>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidValidationTypeSourceDir,
    invalidValidationTypeOutputDir,
    "Invalid validation generic type compiled successfully.",
    "@:validates field titleValidation must use Validation<String> for target title"
  );
}

function expectInvalidEnumShapeFailure() {
  mkdirSync(join(invalidEnumShapeSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidEnumShapeSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidEnumShapeSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn",
    "\t@:railsEnum(\"open\")",
    "\tpublic var status:String;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidEnumShapeSourceDir,
    invalidEnumShapeOutputDir,
    "Invalid enum shape compiled successfully.",
    "@:railsEnum expects one options object"
  );
}

function expectInvalidEnumValueFailure() {
  mkdirSync(join(invalidEnumValueSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidEnumValueSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidEnumValueSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn",
    "\t@:railsEnum({open: true})",
    "\tpublic var status:String;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidEnumValueSourceDir,
    invalidEnumValueOutputDir,
    "Invalid enum value compiled successfully.",
    "@:railsEnum value open must be a String or Int literal"
  );
}

function expectInvalidEnumTypeFailure() {
  mkdirSync(join(invalidEnumTypeSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidEnumTypeSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidEnumTypeSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn",
    "\t@:railsEnum({open: \"open\"})",
    "\tpublic var status:Int;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidEnumTypeSourceDir,
    invalidEnumTypeOutputDir,
    "Invalid enum field type compiled successfully.",
    "@:railsEnum status values are String literals, so the field must be String"
  );
}

function expectInvalidCallbackStaticFailure() {
  mkdirSync(join(invalidCallbackStaticSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidCallbackStaticSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidCallbackStaticSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:beforeSave public static function normalizeTitle():Void {}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidCallbackStaticSourceDir,
    invalidCallbackStaticOutputDir,
    "Invalid static callback compiled successfully.",
    ":beforeSave callback methods must be instance methods"
  );
}

function expectInvalidCallbackArgsFailure() {
  mkdirSync(join(invalidCallbackArgsSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidCallbackArgsSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidCallbackArgsSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:beforeSave public function normalizeTitle(value:String):Void {}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidCallbackArgsSourceDir,
    invalidCallbackArgsOutputDir,
    "Invalid callback with args compiled successfully.",
    ":beforeSave callback methods must not declare arguments"
  );
}

function expectInvalidCallbackNameFailure() {
  mkdirSync(join(invalidCallbackNameSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidCallbackNameSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidCallbackNameSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsCallback(\"before_magic\") public function normalizeTitle():Void {}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidCallbackNameSourceDir,
    invalidCallbackNameOutputDir,
    "Invalid callback name compiled successfully.",
    "@:railsCallback unknown callback before_magic"
  );
}

function expectInvalidCallbackFieldFailure() {
  mkdirSync(join(invalidCallbackFieldSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidCallbackFieldSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidCallbackFieldSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:beforeSave public var title:String;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidCallbackFieldSourceDir,
    invalidCallbackFieldOutputDir,
    "Invalid callback field compiled successfully.",
    ":beforeSave can only be used on model methods"
  );
}

function expectInvalidFindValueTypeFailure() {
  mkdirSync(invalidFindSourceDir, { recursive: true });
  writeFileSync(join(invalidFindSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.find(\"nope\");",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidFindSourceDir,
    invalidFindOutputDir,
    "Invalid ActiveRecord find id type compiled successfully.",
    "String should be Int"
  );
}

function expectInvalidRelationFindValueTypeFailure() {
  mkdirSync(invalidRelationFindSourceDir, { recursive: true });
  writeFileSync(join(invalidRelationFindSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.where({status: \"open\"}).find({id: 1});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidRelationFindSourceDir,
    invalidRelationFindOutputDir,
    "Invalid ActiveRecord relation find id type compiled successfully.",
    "String"
  );
}

function expectInvalidFindByFieldFailure() {
  mkdirSync(invalidFindBySourceDir, { recursive: true });
  writeFileSync(join(invalidFindBySourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.findBy({missing: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidFindBySourceDir,
    invalidFindByOutputDir,
    "Invalid ActiveRecord findBy field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidScopeInstanceFailure() {
  mkdirSync(join(invalidScopeInstanceSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidScopeInstanceSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidScopeInstanceSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var title:String;",
    "\t@:railsScope public function badScope() {",
    "\t\treturn BadTodo.where({title: \"bad\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidScopeInstanceSourceDir,
    invalidScopeInstanceOutputDir,
    "Invalid ActiveRecord instance scope compiled successfully.",
    "@:railsScope must annotate a static model method."
  );
}

function expectInvalidDefaultScopeArgsFailure() {
  mkdirSync(join(invalidDefaultScopeArgsSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidDefaultScopeArgsSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidDefaultScopeArgsSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var title:String;",
    "\t@:railsDefaultScope public static function badDefaultScope(title:String) {",
    "\t\treturn BadTodo.where({title: title});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidDefaultScopeArgsSourceDir,
    invalidDefaultScopeArgsOutputDir,
    "Invalid ActiveRecord default scope with args compiled successfully.",
    "@:railsDefaultScope methods cannot take arguments."
  );
}

function expectInvalidCompile(sourceDir, rubyOutputDir, successMessage, expectedDiagnostic) {
  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${rubyOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      join(root, "examples", "active_record_model"),
      "-cp",
      sourceDir,
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
      console.error(successMessage);
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes(expectedDiagnostic)) {
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      console.error(`Invalid ActiveRecord compile failed without expected diagnostic: ${expectedDiagnostic}`);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to find Reflaxe source for invalid ActiveRecord compile check.");
    process.exit(1);
  }
}

function expectInvalidColumnDefaultFailure() {
  mkdirSync(join(invalidSourceDir, "models"), { recursive: true });
  writeFileSync(join(invalidSourceDir, "Main.hx"), [
    "import models.BadModel;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad:BadModel = null;",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "models", "BadModel.hx"), [
    "package models;",
    "",
    "@:railsModel",
    "class BadModel extends rails.active_record.Base<BadModel> {",
    "\t@:railsColumn({defaultValue: \"not_bool\"})",
    "\tpublic var enabled:Bool;",
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
      invalidSourceDir,
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
      console.error("Expected invalid ActiveRecord column defaultValue compile to fail.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("@:railsColumn defaultValue for Bool fields must be a Bool literal.")) {
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      console.error("Invalid ActiveRecord column defaultValue failed without the expected diagnostic.");
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to find Reflaxe source for invalid ActiveRecord compile check.");
    process.exit(1);
  }
}
