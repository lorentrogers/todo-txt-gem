require 'date'

module Todo
  class Task
    include Comparable
    include Todo::Logger
    include Todo::Syntax

    # Creates a new task. The argument that you pass in must be the string
    # representation of a task.
    #
    # Example:
    #
    #   task = Todo::Task.new("(A) A high priority task!")
    def initialize task
      @orig = task
      @completed_on = get_completed_date(orig)
      @priority, @created_on = orig_priority(orig), orig_created_on(orig)
      @due_on = get_due_on_date(orig)
      @contexts ||= extract_contexts(orig)
      @projects ||= extract_projects(orig)
    end

    # Returns the original content of the task.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) @context +project Hello!"
    #   task.orig #=> "(A) @context +project Hello!"
    attr_reader :orig

    # Returns the task's creation date, if any.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) 2012-03-04 Task."
    #   task.created_on
    #   #=> <Date: 2012-03-04 (4911981/2,0,2299161)>
    #
    # Dates _must_ be in the YYYY-MM-DD format as specified in the todo.txt
    # format. Dates in any other format will be classed as malformed and this
    # attribute will be nil.
    attr_reader :created_on

    # Returns the task's completion date if task is done.
    #
    # Example:
    #
    #   task = Todo::Task.new "x 2012-03-04 Task."
    #   task.completed_on
    #   #=> <Date: 2012-03-04 (4911981/2,0,2299161)>
    #
    # Dates _must_ be in the YYYY-MM-DD format as specified in the todo.txt
    # format. Dates in any other format will be classed as malformed and this
    # attribute will be nil.
    attr_reader :completed_on

    # Returns the task's due date, if any.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) This is a task. due:2012-03-04"
    #   task.due_on
    #   #=> <Date: 2012-03-04 (4911981/2,0,2299161)>
    #
    # Dates _must_ be in the YYYY-MM-DD format as specified in the todo.txt
    # format. Dates in any other format will be classed as malformed and this
    # attribute will be nil.
    attr_reader :due_on

    # Returns the priority, if any.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) Some task."
    #   task.priority #=> "A"
    #
    #   task = Todo::Task.new "Some task."
    #   task.priority #=> nil
    attr_reader :priority

    # Returns an array of all the @context annotations.
    #
    # Example:
    #
    #   task = Todo:Task.new "(A) @context Testing!"
    #   task.context #=> ["@context"]
    attr_reader :contexts

    # Returns an array of all the +project annotations.
    #
    # Example:
    #
    #   task = Todo:Task.new "(A) +test Testing!"
    #   task.projects #=> ["+test"]
    attr_reader :projects

    # Gets just the text content of the todo, without the priority, contexts
    # and projects annotations.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) @test Testing!"
    #   task.text #=> "Testing!"
    def text
      @text ||= get_item_text(orig)
    end

    # Returns the task's creation date, if any.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) 2012-03-04 Task."
    #   task.date
    #   #=> <Date: 2012-03-04 (4911981/2,0,2299161)>
    #
    # Dates _must_ be in the YYYY-MM-DD format as specified in the todo.txt
    # format. Dates in any other format will be classed as malformed and this
    # method will return nil.
    #
    # Deprecated
    def date
      logger.warn("Task#date is deprecated, use created_on instead.")

      @created_on
    end

    # Returns whether a task's due date is in the past.
    #
    # Example:
    #
    #   task = Todo::Task.new("This task is overdue! due:#{Date.today - 1}")
    #   task.overdue?
    #   #=> true
    def overdue?
      !due_on.nil? && due_on < Date.today
    end

    # Returns if the task is done.
    #
    # Example:
    #
    #   task = Todo::Task.new "x 2012-12-08 Task."
    #   task.done?
    #   #=> true
    #
    #   task = Todo::Task.new "Task."
    #   task.done?
    #   #=> false
    def done?
      !@completed_on.nil?
    end

    # Completes the task on the current date.
    #
    # Example:
    #
    #   task = Todo::Task.new "2012-12-08 Task."
    #   task.done?
    #   #=> false
    #
    #   task.do!
    #   task.done?
    #   #=> true
    #   task.created_on
    #   #=> <Date: 2012-12-08 (4911981/2,0,2299161)>
    #   task.completed_on
    #   #=> # the current date
    def do!
      @completed_on = Date.today
    end

    # Marks the task as incomplete and resets its original priority.
    #
    # Example:
    #
    #   task = Todo::Task.new "x 2012-12-08 2012-03-04 Task."
    #   task.done?
    #   #=> true
    #
    #   task.undo!
    #   task.done?
    #   #=> false
    #   task.created_on
    #   #=> <Date: 2012-03-04 (4911981/2,0,2299161)>
    #   task.completed_on
    #   #=> nil
    def undo!
      @completed_on = nil
    end

    # Toggles the task from complete to incomplete or vice versa.
    #
    # Example:
    #
    #   task = Todo::Task.new "x 2012-12-08 Task."
    #   task.done?
    #   #=> true
    #
    #   task.toggle!
    #   task.done?
    #   #=> false
    #
    #   task.toggle!
    #   task.done?
    #   #=> true
    def toggle!
      done? ? undo! : do!
    end

    # Returns this task as a string.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) 2012-12-08 Task"
    #   task.to_s
    #   #=> "(A) 2012-12-08 Task"
    def to_s
      if done?
        compile_done_string
      else
        compile_string
      end
    end

    # Compares the priorities of two tasks.
    #
    # Example:
    #
    #   task1 = Todo::Task.new "(A) Priority A."
    #   task2 = Todo::Task.new "(B) Priority B."
    #
    #   task1 > task2
    #   # => true
    #
    #   task1 == task2
    #   # => false
    #
    #   task2 > task1
    #   # => false
    def <=> other_task
      if self.priority.nil? and other_task.priority.nil?
        0
      elsif other_task.priority.nil?
        1
      elsif self.priority.nil?
        -1
      else
        other_task.priority <=> self.priority
      end
    end

    private

    # Returns the priority of the Task, formatted depending on the
    # completion state. If the task is incomplete, it will use the
    # `(A)` format, if it is complete, it will use ` priority:A`.
    def str_priority
      if done?
        priority ? " priority:#{priority}" : ''
      else
        priority ? "(#{priority}) " : ''
      end
    end

    # Returns the completion status for the Task as an `x` with date
    # if the task has been completed.
    def str_done
      done? ? "x #{completed_on} " : ''
    end

    # Returns the creation date for the Task, formatted as a string.
    def str_created_on
      created_on ? "#{created_on} " : ''
    end

    # Returns the contexts for the Task, formatted as a string.
    # If none exists, it returns an empty string.
    def str_contexts
      contexts.empty? ? '' : " #{contexts.join ' '}"
    end

    # Returns the projects for the Task, formatted as a string.
    # If none exists, it returns an empty string.
    def str_projects
      projects.empty? ? '' : " #{projects.join ' '}"
    end

    # Returns the due date for the Task, formatted as a string.
    # If none exists, it returns an empty string.
    def str_due_on
      due_on.nil? ? '' : " due:#{due_on}"
    end

    # Returns the properly formatted string for Task#to_s.
    # This method formats the string as though it has not yet been completed.
    def compile_string
      str_priority +
        str_created_on +
        text +
        str_contexts +
        str_projects +
        str_due_on
    end

    # Returns the properly formatted string for Task#to_s.
    # This method formats the string as though it has been completed.
    def compile_done_string
      str_done +
        str_created_on +
        text +
        str_contexts +
        str_projects +
        str_due_on +
        str_priority
    end
  end
end
