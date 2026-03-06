--Test Business logic

-- Test: function returns correct status before a known status change
-- TB-22 moved from "To Do" to "Ready for Dev" on 2024-10-27
-- Querying 2024-10-01 should return "To Do"

select *
from dbt_dev_gal.issue_status_as_of('TB-22', '2024-10-01')
where status_as_of != 'To Do'
-- if this returns any rows, the test fails