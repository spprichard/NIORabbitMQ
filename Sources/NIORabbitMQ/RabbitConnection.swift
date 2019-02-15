import NIO
import NIOConcurrencyHelpers

public final class RabbitConnection {
    public let channel: Channel
    
    init(channel: Channel) {
        self.channel = channel
    }
    
    public func close() -> EventLoopFuture<Void> {
        return self.channel.close(mode: .all)
    }
    
    // TODO: Make actual request type
    public func send(_ request: String) -> EventLoopFuture<Void> {
        let promise = self.channel.eventLoop.newPromise(of: Void.self)
        self.channel.write(request).cascade(promise: promise)
        self.channel.flush()
        return promise.futureResult
    }
    
    public func connect(to host: String, _ port: Int,  on eventloop: EventLoop) -> EventLoopFuture<Channel> {
        let bootstrap = ClientBootstrap(group: eventloop)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.add(handler: BackPressureHandler()).then {
                    channel.pipeline.add(handler: RabbitConnectionHandler())
                }
            }
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        return bootstrap.connect(host: host, port: port)
    }
}


