import Foundation
import NIO

public protocol RabbitConnectionRequest{
    func respond(to message: RabbitMessage) throws -> [RabbitMessage]?
    func start() throws -> [RabbitMessage]
}

public final class RabbitConnectionRequestContext {
    let delegate: RabbitConnectionRequest
    let promise: EventLoopPromise<Void>
    var error: Error?
    
    init(delegate: RabbitConnectionRequest,  promise: EventLoopPromise<Void>) {
        self.delegate = delegate
        self.promise = promise
    }
}


public final class RabbitConnectionHandler: ChannelDuplexHandler {
    public typealias InboundIn = RabbitMessage
    public typealias OutboundIn = RabbitConnectionRequestContext
    public typealias OutboundOut = RabbitMessage
    
    private var queue: [RabbitConnectionRequestContext]
    
    public init() {
        self.queue = []
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        do {
            let message = self.unwrapInboundIn(data)
            
            guard self.queue.count > 0 else {
                assertionFailure("Rabbit queue empty, disgard: \(message)")
                return
            }
            
            let request = self.queue[0]
            
            if let responses = try request.delegate.respond(to: message) {
                for response in responses {
                    ctx.write(self.wrapOutboundOut(response), promise: nil)
                }
                ctx.flush()
            } else {
                self.queue.removeFirst()
                if let error = request.error {
                    request.promise.fail(error: error)
                } else {
                    request.promise.succeed(result: ())
                }
            }
        } catch let error {
            self.errorCaught(ctx: ctx, error: error)
        }
    }
    
    public func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        do {
            let request = self.unwrapOutboundIn(data)
            self.queue.append(request)
            let messages = try request.delegate.start()
            for message in messages {
                ctx.write(self.wrapOutboundOut(message), promise: nil)
            }
            ctx.flush()            
        } catch let error {
            self.errorCaught(ctx: ctx, error: error)
        }
        
    }
    
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        guard self.queue.count > 0 else {
            assertionFailure("Rabbit Queue Empty, disregard: \(error.localizedDescription)")
            return
        }
        
        self.queue[0].promise.fail(error: error)
        ctx.close(mode: .all, promise: nil)
    }
    
}

//public final class RabbitConnectionHandler: ChannelInboundHandler {
//    public typealias InboundIn = ByteBuffer
//    public typealias OutboundOut = ByteBuffer
//    private var numBytes = 0
//
//    // channel is connected, send a message
//    public func channelActive(ctx: ChannelHandlerContext) {
//        let message = "SwiftNIO rocks!"
//        var buffer = ctx.channel.allocator.buffer(capacity: message.utf8.count)
//        buffer.write(string: message)
//        ctx.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
//    }
//
//    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
//        var buffer = unwrapInboundIn(data)
//        let readableBytes = buffer.readableBytes
//        if let received = buffer.readString(length: readableBytes) {
//            print(received)
//        }
//        if numBytes == 0 {
//            print("nothing left to read, close the channel")
//            ctx.close(promise: nil)
//        }
//    }
//
//    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
//        print("error: \(error.localizedDescription)")
//        ctx.close(promise: nil)
//    }
//
//}
