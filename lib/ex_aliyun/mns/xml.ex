defmodule ExAliyun.MNS.Xml do
  @moduledoc false

  require EEx

  EEx.function_from_file(:def, :generate_queue, "lib/ex_aliyun/mns/xml/queue.eex", [:queue],
    trim: true
  )

  EEx.function_from_file(:def, :generate_topic, "lib/ex_aliyun/mns/xml/topic.eex", [:topic],
    trim: true
  )

  EEx.function_from_file(:def, :generate_messages, "lib/ex_aliyun/mns/xml/messages.eex", [:messages],
    trim: true
  )

  EEx.function_from_file(:def, :generate_message, "lib/ex_aliyun/mns/xml/message.eex", [:message],
    trim: true
  )

  EEx.function_from_file(
    :def,
    :generate_receipt_handles,
    "lib/ex_aliyun/mns/xml/receipt_handles.eex",
    [:receipt_handles],
    trim: true
  )

  EEx.function_from_file(
    :def,
    :generate_subscription,
    "lib/ex_aliyun/mns/xml/subscription.eex",
    [:subscription],
    trim: true
  )

  EEx.function_from_file(
    :def,
    :generate_topic_message,
    "lib/ex_aliyun/mns/xml/topic_message.eex",
    [:message],
    trim: true
  )
end
