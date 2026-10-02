"""Generate original test books, including a 12-page CBZ and a tall-page PDF."""
from pathlib import Path
import struct, zlib, zipfile, os
ROOT=Path(__file__).resolve().parents[1]
LIB=Path(os.getenv('YOMIGAMI_HOME',str(ROOT/'build/dev-data')))/'library'
LIB.mkdir(parents=True,exist_ok=True)
def pdf(path,title,pages=4,tall=False,index=0):
    objects=[]
    def add(data): objects.append(data);return len(objects)
    add(b'<< /Type /Catalog /Pages 2 0 R >>')
    kids=' '.join(f'{5+i*2} 0 R' for i in range(pages))
    add(f'<< /Type /Pages /Kids [{kids}] /Count {pages} >>'.encode())
    add(b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>')
    for i in range(pages):
        h=1500 if tall else 720
        content=f'0.95 g 0 0 480 {h} re f 0 g\n'
        if i==0:
            content+=f'0.1 g 28 28 424 {h-56} re f 1 g\n'
            content+=f'BT /F1 16 Tf 48 {h-72} Td (Y O M I G A M I) Tj ET\n'
            for n,line in enumerate(title.split(' ')):
                content+=f'BT /F1 46 Tf 48 {h-160-n*55} Td ({line}) Tj ET\n'
            for n in range(12):
                inset=(n*13+index*7)%120
                content+=f'0.6 G {48+inset} {100+n*13} m {425-inset} {180+n*16} l S\n'
            content+=f'1 g BT /F1 14 Tf 48 65 Td (ORIGINAL TEST EDITION / {pages} PAGES) Tj ET\n'
        else:
            content+=f'BT /F1 28 Tf 40 {h-65} Td ({title} / Page {i+1}) Tj ET\n'
            for y in range(100,h-100,140):
                content+=f'0.2 G 40 {y} 400 105 re S BT /F1 18 Tf 60 {y+50} Td (Reading panel / {y}) Tj ET\n'
        data=content.encode();stream=add(b'<< /Length '+str(len(data)).encode()+b' >>\nstream\n'+data+b'endstream')
        add(f'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 480 {h}] /Resources << /Font << /F1 3 0 R >> >> /Contents {stream} 0 R >>'.encode())
    output=b'%PDF-1.4\n';offsets=[0]
    for i,obj in enumerate(objects,1): offsets.append(len(output));output+=f'{i} 0 obj\n'.encode()+obj+b'\nendobj\n'
    xref=len(output);output+=f'xref\n0 {len(objects)+1}\n0000000000 65535 f \n'.encode()
    output+=b''.join(f'{p:010} 00000 n \n'.encode() for p in offsets[1:])
    output+=f'trailer << /Size {len(objects)+1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n'.encode()
    path.write_bytes(output)
def png(number):
    w,h=360,540;rows=[]
    for y in range(h):
        row=bytearray()
        for x in range(w):
            v=242
            if 22<x<338 and 22<y<518:
                v=255 if y<120 else (40 if (x//45+y//90+number)%2==0 else 210)
                if 35<x<35+number*22 and 45<y<88:v=20
            row.append(v)
        rows.append(b'\0'+row)
    def chunk(t,d):return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,0,0,0,0))+chunk(b'IDAT',zlib.compress(b''.join(rows)))+chunk(b'IEND',b'')
for i,title in enumerate(['Moon Atlas','The Quiet Sea','Field Notes','Paper Gardens','Long Horizons']):
    pdf(LIB/(title+'.pdf'),title,tall=title=='Long Horizons',index=i)
with zipfile.ZipFile(LIB/'Ink Journey.cbz','w',zipfile.ZIP_DEFLATED) as z:
    for page in range(1,13):z.writestr(f'{page:03}.png',png(page))
    z.writestr('ComicInfo.xml','<ComicInfo><Title>Ink Journey</Title><PageCount>12</PageCount></ComicInfo>')
print('Generated five PDFs and one 12-page CBZ, all original fixtures.')

# Original reflowable fixture; kept outside library so six-book UI fixtures remain stable.
with zipfile.ZipFile(LIB.parent/'Reader-layout.epub','w') as z:
    z.writestr('mimetype','application/epub+zip')
    z.writestr('META-INF/container.xml','<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0"><rootfiles><rootfile full-path="content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>')
    z.writestr('content.opf','<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="id"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>Layout Test</dc:title><dc:identifier id="id">yomi-layout-test</dc:identifier><dc:language>en</dc:language></metadata><manifest><item id="text" href="text.xhtml" media-type="application/xhtml+xml"/></manifest><spine><itemref idref="text"/></spine></package>')
    z.writestr('text.xhtml','<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Test</title></head><body>'+''.join('<p>Passage '+str(i)+'. Reading is a journey through ideas. These original words verify page selection and font layout.</p>' for i in range(150))+'</body></html>')
