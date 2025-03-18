local completionist = require('completionist')

describe('current_task', function()
    before_each(function()
        completionist.notes = {}
    end)

    it('should return empty string when no notes exist', function()
        assert.are.equal("", completionist.current_task())
    end)

    it('should return single note when only root notes exist', function()
        completionist.notes = {
            { note = "Low priority",    priority = "low" },
            { note = "High priority",   priority = "high" },
            { note = "Medium priority", priority = "medium" }
        }
        assert.are.equal("High priority", completionist.current_task())
    end)

    it('should follow highest priority path through nested notes', function()
        completionist.notes = {
            {
                note = "Work",
                priority = "high",
                subnotes = {
                    {
                        note = "Project A",
                        priority = "medium",
                        subnotes = {
                            { note = "Fix bug",    priority = "high" },
                            { note = "Write docs", priority = "low" }
                        }
                    },
                    {
                        note = "Project B",
                        priority = "low",
                        subnotes = {
                            { note = "Review PR", priority = "high" }
                        }
                    }
                }
            },
            {
                note = "Personal",
                priority = "low",
                subnotes = {
                    { note = "Gym", priority = "high" }
                }
            }
        }
        assert.are.equal("Work > Project A > Fix bug", completionist.current_task())
    end)

    it('should handle notes with no priority set', function()
        completionist.notes = {
            {
                note = "Task 1",
                subnotes = {
                    { note = "Subtask 1" }
                }
            },
            {
                note = "Task 2",
                priority = "high",
                subnotes = {
                    { note = "Subtask 2" }
                }
            }
        }
        assert.are.equal("Task 2 > Subtask 2", completionist.current_task())
    end)

    it('should handle empty subnotes arrays', function()
        completionist.notes = {
            {
                note = "Task 1",
                priority = "high",
                subnotes = {}
            },
            {
                note = "Task 2",
                priority = "medium",
                subnotes = {
                    { note = "Subtask 1", priority = "high" }
                }
            }
        }
        assert.are.equal("Task 1", completionist.current_task())
    end)
end)
