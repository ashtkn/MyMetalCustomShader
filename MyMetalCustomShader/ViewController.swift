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
    
    // For timer
    private var timer: Timer?
    
    // For MetalKit
    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    
    private var vertexBuffer: MTLBuffer!
    private var resolutionBuffer: MTLBuffer!
    private var timeBuffer: MTLBuffer!
    
    private var renderPipelineState: MTLRenderPipelineState!
    private let renderPassDescriptor = MTLRenderPassDescriptor()
    
    @IBOutlet private weak var mtkView: MTKView! {
        didSet {
            mtkView.device = device
            mtkView.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make command queue
        commandQueue = device.makeCommandQueue()!
        
        // Make buffers
        makeVertexBuffer()
        makeResolutionBuffer()
        makeTimeBuffer()
        
        // Make pipline
        makeRenderPipelineState()
    }
    
    private func makeVertexBuffer() {
        let vertexData = Store.default.vertexData
        let size = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: size)
    }
    
    private func makeResolutionBuffer() {
        let resolutionData = Store.default.resolutionData
        let size = resolutionData.count * MemoryLayout<Float>.size
        resolutionBuffer = device.makeBuffer(bytes: resolutionData, length: size, options: [])
    }
    
    private func makeTimeBuffer() {
        let size = MemoryLayout<Float>.size
        timeBuffer = device.makeBuffer(length: size, options: [])
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
        let startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: .init(1 / fps), repeats: true) { [weak self] _ in
            guard let timeBuffer = self?.timeBuffer else { return }
            let pTimeData = timeBuffer.contents()
            let vTimeData = pTimeData.bindMemory(to: Float.self, capacity: 1 / MemoryLayout<Float>.stride)
            vTimeData[0] = Float(Date().timeIntervalSince(startDate))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
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

