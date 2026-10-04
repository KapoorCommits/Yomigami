import Foundation
import CoreGraphics
import ImageIO
let args=CommandLine.arguments
let src=CGImageSourceCreateWithURL(URL(fileURLWithPath:args[1]) as CFURL,nil)!
let image=CGImageSourceCreateImageAtIndex(src,0,nil)!
let h=Int(args[3])!,w=Int(Double(image.width)*Double(h)/Double(image.height))
let gray=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:w,space:CGColorSpaceCreateDeviceGray(),bitmapInfo:0)!
gray.interpolationQuality = .high
gray.draw(image,in:CGRect(x:0,y:0,width:w,height:h))
let input=gray.data!.assumingMemoryBound(to:UInt8.self)
let stride=(w+1)/2
var pixels=[UInt8](repeating:0,count:stride*h)
for y in 0..<h {for x in 0..<w {let v=UInt8((Int(input[y*w+x])*15+127)/255);pixels[y*stride+x/2] |= x%2==0 ? v<<4 : v}}
var table=[UInt8]();for i in 0..<16 {table += [UInt8(i*17),UInt8(i*17),UInt8(i*17)]}
let space=CGColorSpace(indexedBaseSpace:CGColorSpaceCreateDeviceRGB(),last:15,colorTable:table)!
let provider=CGDataProvider(data:Data(pixels) as CFData)!
let result=CGImage(width:w,height:h,bitsPerComponent:4,bitsPerPixel:4,bytesPerRow:stride,space:space,bitmapInfo:CGBitmapInfo(rawValue:0),provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent)!
let dest=CGImageDestinationCreateWithURL(URL(fileURLWithPath:args[2]) as CFURL,"public.png" as CFString,1,nil)!
CGImageDestinationAddImage(dest,result,nil);assert(CGImageDestinationFinalize(dest))
print("\(w)x\(h): \((try! Data(contentsOf:URL(fileURLWithPath:args[2]))).count) bytes")
