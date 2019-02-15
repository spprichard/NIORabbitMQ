import NIO

public struct RabbitMessage {
    var data: ByteBuffer
    
    init(data: ByteBuffer) {
        self.data = data
    }
}
