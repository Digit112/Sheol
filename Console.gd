extends LineEdit

var expression = Expression.new()

func _on_text_submitted(new_text):
	expression.parse(new_text)
	var result = expression.execute()
	if result != null:
		print(result)
