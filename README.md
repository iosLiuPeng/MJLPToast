# MJLPToast  
  
  
1. 取keyWindow作为承载，所以：  
不依赖控制器  
不需创建新window  
不会挡住键盘（键盘在keyWindow之上）    
不会影响下面视图的事件传递  
  
2. 没有NSTimer  
使用dispatch_after自动关闭，所以不用担心引用持有问题  
   
3. 支持堆叠消息、只显示最新消息两种模式  
   
4. 适配处理  
  
5. 点击立即消失  