//
//  ViewController.swift
//  MyMetalCustomShader
//
//  Created by 竹ノ内朝陽 on 2020/04/09.
//  Copyright © 2020 竹ノ内朝陽. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    private let vertexData: [Float] = [
        -1, -1, 0, 1,
        1, -1, 0, 1,
        -1,  1, 0, 1,
        1,  1, 0, 1
    ]
    
    private let resolutionData: [Float] = [
        Float(UIScreen.main.nativeBounds.size.width),
        Float(UIScreen.main.nativeBounds.size.height)
    ]
    
    private let timeData: [Float] = [0]
    
    private let startDate: Date = Date()
    
    private var timer: Timer?
    
    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    
    private var vertexBuffer: MTLBuffer!
    private var resolutionBuffer: MTLBuffer!
    private var timeBuffer: MTLBuffer!
    
    private var renderPipelineState: MTLRenderPipelineState!
    private let renderPassDescriptor = MTLRenderPassDescriptor()
    
    @IBOutlet private weak var mtkView: MTKView!{
        didSet {
            mtkView.device = device
            mtkView.delegate = self
            // mtkView.enableSetNeedsDisplay = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commandQueue = device.makeCommandQueue()!
        makeBuffers()
        makeRenderPipelineState()
    }
    
    private func makeBuffers() {
        makeVertexBuffer()
        makeResolutionBuffer()
        makeTimeBuffer()
    }
    
    private func makeVertexBuffer() {
        let size = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: size)
    }
    
    private func makeResolutionBuffer() {
        let size = resolutionData.count * MemoryLayout<Float>.size
        resolutionBuffer = device.makeBuffer(bytes: resolutionData, length: size, options: [])
    }
    
    private func makeTimeBuffer() {
        let size = timeData.count * MemoryLayout<Float>.size
        timeBuffer = device.makeBuffer(bytes: timeData, length: size, options: [])
    }
    
    private func makeRenderPipelineState() {
        let library = device.makeDefaultLibrary()!
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let fps: Float = 30
        timer = Timer.scheduledTimer(withTimeInterval: .init(1 / fps), repeats: true) { [weak self] timer in
            self?.updateTimeBuffer()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }
    
    private func updateTimeBuffer() {
        let pTimeData = timeBuffer.contents()
        let vTimeData = pTimeData.bindMemory(to: Float.self, capacity: 1 / MemoryLayout<Float>.stride)
        vTimeData[0] = Float(Date().timeIntervalSince(startDate))
    }
    
}

extension ViewController: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func draw(in view: MTKView) {
        let drawable = view.currentDrawable!
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        guard let renderPipelineState = renderPipelineState else { fatalError() }
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(resolutionBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(timeBuffer, offset: 0, index: 1)

        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}

