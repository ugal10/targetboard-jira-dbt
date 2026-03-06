Targetboard Jira dbt Project
A production-style dbt project that cleans raw Jira data (loaded via Stitch Data) and exposes a Postgres SQL function to query the status of any issue as of a given date.

Architecture
This project follows a layered data pipeline approach:
Raw (Stitch/Jira)
    ↓
Staging Layer       → light renaming, type casting, no business logic
    ↓
DWH Layer           → cleaning, filtering, business logic
    ↓
SQL Function        → issue_status_as_of() queries the DWH layer
Why this approach?

Raw layer is never touched — Stitch loads data into targetboard_source_jira, we only read from it
Staging isolates source changes — if Stitch renames a column, only the staging model needs updating
DWH contains all business logic — filtering, cleaning, and transformations are centralized
Function queries DWH, not raw — as required, the function never touches raw tables directly


Project Structure
targetboard_jira/
├── models/
│   ├── stg/                          # Staging layer (views)
│   │   ├── stg_jira_issues.sql
│   │   ├── stg_jira_changelogs.sql
│   │   └── stg_jira_changelogs_items.sql
│   └── dwh/                          # DWH layer (tables)
│       ├── dim_issues.sql
│       ├── fct_issue_status_history.sql
│       └── schema.yml
├── analyses/
│   └── issue_status_as_of_example.sql   # Example queries
├── tests/
│   └── test_issue_status_as_of.sql      # Function logic test
├── sql/
│   └── issue_status_as_of.sql           # Postgres function DDL
└── dbt_project.yml

Models
Staging Layer
Staging models are materialized as views — they simply rename and cast raw columns, adding no business logic. This keeps them lightweight and always in sync with the source.
stg_jira_issues
Reads from targetboard_source_jira.issues. Selects and renames the key fields needed downstream:

issue_id, issue_key, summary, issue_type, current_status
project_key, project_name, assignee_name, reporter_name
created_at, updated_at

Note: camelCase columns from Stitch (e.g. fields__assignee__displayName) are quoted to preserve case in Postgres.
stg_jira_changelogs
Reads from targetboard_source_jira.changelogs. One row per change event on an issue.

changelog_id, issue_id, changed_at

stg_jira_changelogs_items
Reads from targetboard_source_jira.changelogs__items. One row per field changed within a changelog event.

changelog_id, field_name, field_type, from_value, to_value


DWH Layer
DWH models are materialized as tables — they contain business logic and are queried by the function.
dim_issues
Built from stg_jira_issues. Applies two cleaning rules:

Filters to only Task, Epic, and Story issue types (drops Bug, Idea, Sub-task, Subtask)
Title-cases summaries using Postgres initcap() function

This is the source of truth for issue metadata.
fct_issue_status_history
Joins stg_jira_changelogs + stg_jira_changelogs_items + dim_issues to build a complete timeline of status changes per issue.
Two parts combined via UNION ALL:

Status changes — from changelog items where field_name = 'status', giving from_status and to_status with timestamps
Initial status — the first from_status at the issue's created_at timestamp, representing the status the issue was born with

This ensures the function can return the correct status even for dates before any changelog entry exists.

SQL Function
dbt_dev_gal.issue_status_as_of(p_issue_key text, p_date date)
Located in sql/issue_status_as_of.sql.
How it works:

Looks up the issue in dim_issues
Filters fct_issue_status_history to all status transitions on or before p_date
Takes the latest transition before that date using DISTINCT ON ... ORDER BY changed_at DESC
Returns issue_key, summary, and status_as_of

Returns:
ColumnTypeDescriptionissue_keytextThe Jira issue key (e.g. TB-22)summarytextTitle-cased issue summarystatus_as_oftextThe status the issue had on p_date
Example
sql-- TB-22 was "To Do" before 2024-10-27
select * from dbt_dev_gal.issue_status_as_of('TB-22', '2024-10-01');
-- Returns: TB-22 | Analyze - When Sorting Should First Sort High -> Low | To Do

-- TB-22 moved to "Ready for Dev" on 2024-10-27
select * from dbt_dev_gal.issue_status_as_of('TB-22', '2024-11-01');
-- Returns: TB-22 | Analyze - When Sorting Should First Sort High -> Low | Ready for Dev

Tests
11 tests total, all passing. Run with dbt test.
Schema tests (models/dwh/schema.yml)
TestModelColumnnot_nulldim_issuesissue_id, issue_key, issue_type, summaryuniquedim_issuesissue_id, issue_keyaccepted_values (Task/Epic/Story)dim_issuesissue_typenot_nullfct_issue_status_historyissue_key, changed_at, to_status
Data test (tests/test_issue_status_as_of.sql)
Validates the function's business logic by querying a known issue (TB-22) before its status change date and asserting the correct status is returned. The test fails if any rows are returned (dbt data test convention).

Setup & Running
Prerequisites

Python 3.x
dbt-core + dbt-postgres: pip install dbt-core dbt-postgres

Configure connection
Edit ~/.dbt/profiles.yml:
yamltargetboard_jira:
  target: dev
  outputs:
    dev:
      type: postgres
      host: <host>
      port: 25060
      dbname: targetboard_production_data_0001
      user: doadmin
      password: <password>
      schema: dbt_dev_gal
      threads: 1
      sslmode: require
Run
bash# Validate connection
dbt debug

# Run all models
dbt run

# Run tests
dbt test

# Generate and view docs
dbt docs generate
dbt docs serve
Deploy the SQL function
Run the DDL manually in your Postgres client:
bashpsql <connection_string> -f sql/issue_status_as_of.sql

Database Schema
SchemaPurposetargetboard_source_jiraRaw tables loaded by Stitch Data — read onlydbt_dev_galAll dbt models (staging + dwh) and the SQL function