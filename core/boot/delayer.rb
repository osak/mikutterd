# -*- coding: utf-8 -*-

miquire :lib, "delayer"

Delayer.default = Delayer.generate_class(priority: [:ui_response,
                                                    :routine_active,
                                                    :ui_passive,
                                                    :routine_passive,
                                                    :ui_favorited],
                                         default: :routine_passive,
                                         expire: 0.02)


Delayer.register_remain_hook do
  Thread.main.wakeup
end

