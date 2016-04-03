module Todo
  # Handles todo.txt lists as an array of Todo::Task objects.
  class List < Array
    # The path to the todo.txt file that you supplied when you created the
    # Todo::List object.
    attr_reader :path

    # Filters the list by priority and returns a new list.
    #
    # Example:
    #
    #   list = Todo::List.new "/path/to/list"
    #   list.by_priority "A" #=> Will be a new list with only priority A tasks
    def by_priority(priority)
      Todo::List.new select { |task| task.priority == priority }
    end

    # Filters the list by context and returns a new list.
    #
    # Example:
    #
    #   list = Todo::List.new "/path/to/list"
    #   list.by_context "@context" #=> Will be a new list with only tasks
    #                                  containing "@context"
    def by_context(context)
      Todo::List.new select { |task| task.contexts.include? context }
    end

    # Filters the list by project and returns a new list.
    #
    # Example:
    #
    #   list = Todo::List.new "/path/to/list"
    #   list.by_project "+project" #=> Will be a new list with only tasks
    #                                  containing "+project"
    def by_project(project)
      Todo::List.new select { |task| task.projects.include? project }
    end

    # Filters the list by completed tasks and returns a new list.
    #
    # Example:
    #
    #   list = Todo::List.new "/path/to/list"
    #   list.by_done #=> Will be a new list with only tasks marked with
    #                    an [x]
    def by_done
      Todo::List.new select(&:done?)
    end

    # Filters the list by incomplete tasks and returns a new list.
    #
    # Example:
    #
    #   list = Todo::List.new "/path/to/list"
    #   list.by_not_done #=> Will be a new list with only incomplete tasks
    def by_not_done
      Todo::List.new select { |task| task.done? == false }
    end

    private

    # Initializes a Todo List object with a path to the corresponding todo.txt
    # file. For example, if your todo.txt file is located at:
    #
    #   /home/sam/Dropbox/todo/todo.txt
    #
    # You would initialize this object like:
    #
    #   list = Todo::List.new "/home/sam/Dropbox/todo/todo-txt"
    #
    # Alternately, you can initialize this object with an array of strings or
    # tasks. If the array is of strings, the strings will be converted into
    # tasks. You can supply a mixed list of string and tasks if you wish.
    #
    # Example:
    #
    #   array = Array.new
    #   array.push "(A) A string task!"
    #   array.push Todo::Task.new("(A) An actual task!")
    #
    #   list = Todo::List.new array
    def initialize(list)
      if list.is_a? Array
        # No file path was given.
        @path = nil
        parse_task_array(list)
      elsif list.is_a? String
        @path = list

        # Read in lines from file, create Todo::Tasks out of them
        # and push them onto self.
        File.open(list) do |file|
          file.each_line { |line| push Todo::Task.new line }
        end
      end
    end

    # Read in lines from file, create TodoCurses::Tasks
    # out of them and push them onto self.
    def read_file_lines(list)
      File.open(list) do |file|
        file.each_line { |line| push TodoCurses::Task.new line }
      end
    end

    # Read through the items given and convert them into the
    # proper objects.
    def parse_task_array(list)
      list.each do |task|
        # If it's a string, make a new task out of it.
        if task.is_a? String
          push Todo::Task.new task
        # If it's a task, just add it.
        elsif task.is_a? Todo::Task
          push task
        end
      end
    end
  end
end
