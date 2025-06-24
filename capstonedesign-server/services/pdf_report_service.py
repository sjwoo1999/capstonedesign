import os
import base64
import tempfile
from datetime import datetime
from typing import Dict, List, Optional
from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT

class PDFReportService:
    def __init__(self):
        """PDF 리포트 생성 서비스 초기화"""
        self.styles = getSampleStyleSheet()
        
        # 커스텀 스타일 정의
        self.custom_styles = {
            'title': ParagraphStyle(
                'CustomTitle',
                parent=self.styles['Heading1'],
                fontSize=24,
                spaceAfter=30,
                alignment=TA_CENTER,
                textColor=colors.darkblue
            ),
            'subtitle': ParagraphStyle(
                'CustomSubtitle',
                parent=self.styles['Heading2'],
                fontSize=16,
                spaceAfter=20,
                textColor=colors.darkblue
            ),
            'section': ParagraphStyle(
                'CustomSection',
                parent=self.styles['Heading3'],
                fontSize=14,
                spaceAfter=15,
                textColor=colors.darkgreen
            ),
            'body': ParagraphStyle(
                'CustomBody',
                parent=self.styles['Normal'],
                fontSize=11,
                spaceAfter=12,
                alignment=TA_LEFT
            ),
            'highlight': ParagraphStyle(
                'CustomHighlight',
                parent=self.styles['Normal'],
                fontSize=11,
                spaceAfter=12,
                alignment=TA_LEFT,
                textColor=colors.darkred,
                backColor=colors.lightgrey
            )
        }
    
    def create_emotion_report(self, 
                            face_result: Dict,
                            audio_result: Dict,
                            text_result: Dict,
                            fusion_result: Dict,
                            cbt_strategy: Dict,
                            gpt_response: Dict) -> Dict:
        """감정 분석 결과를 PDF 리포트로 생성"""
        try:
            # 임시 PDF 파일 생성
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.pdf')
            temp_file.close()
            
            # PDF 문서 생성
            doc = SimpleDocTemplate(temp_file.name, pagesize=A4)
            story = []
            
            # 제목 페이지
            story.extend(self.create_title_page())
            story.append(PageBreak())
            
            # 요약 페이지
            story.extend(self.create_summary_page(fusion_result))
            story.append(PageBreak())
            
            # 상세 분석 페이지
            story.extend(self.create_detailed_analysis_page(
                face_result, audio_result, text_result, fusion_result
            ))
            story.append(PageBreak())
            
            # CBT 전략 페이지
            story.extend(self.create_cbt_strategy_page(cbt_strategy))
            story.append(PageBreak())
            
            # GPT 조언 페이지
            story.extend(self.create_gpt_advice_page(gpt_response))
            story.append(PageBreak())
            
            # PDF 생성
            doc.build(story)
            
            # PDF를 Base64로 인코딩
            with open(temp_file.name, 'rb') as pdf_file:
                pdf_content = pdf_file.read()
                pdf_base64 = base64.b64encode(pdf_content).decode('utf-8')
            
            # 임시 파일 삭제
            os.unlink(temp_file.name)
            
            return {
                'success': True,
                'pdf_base64': pdf_base64,
                'file_size': len(pdf_content),
                'filename': f'emotion_report_{datetime.now().strftime("%Y%m%d_%H%M%S")}.pdf'
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'PDF generation failed: {str(e)}'
            }
    
    def create_title_page(self) -> List:
        """제목 페이지 생성"""
        story = []
        
        # 메인 제목
        title = Paragraph("멀티모달 감정 분석 리포트", self.custom_styles['title'])
        story.append(title)
        story.append(Spacer(1, 50))
        
        # 부제목
        subtitle = Paragraph("AI 기반 종합 감정 분석 및 CBT 전략 제안", self.custom_styles['subtitle'])
        story.append(subtitle)
        story.append(Spacer(1, 30))
        
        # 생성 날짜
        date_text = f"생성일: {datetime.now().strftime('%Y년 %m월 %d일 %H:%M')}"
        date_para = Paragraph(date_text, self.custom_styles['body'])
        story.append(date_para)
        story.append(Spacer(1, 20))
        
        # 리포트 개요
        overview = """
        이 리포트는 얼굴 표정, 음성, 텍스트 분석을 통한 종합적인 감정 분석 결과와 
        인지행동치료(CBT) 기반의 개인화된 감정 관리 전략을 제공합니다.
        """
        overview_para = Paragraph(overview, self.custom_styles['body'])
        story.append(overview_para)
        
        return story
    
    def create_summary_page(self, fusion_result: Dict) -> List:
        """요약 페이지 생성"""
        story = []
        
        # 페이지 제목
        title = Paragraph("감정 분석 요약", self.custom_styles['subtitle'])
        story.append(title)
        story.append(Spacer(1, 20))
        
        if fusion_result.get('success'):
            # 주요 결과 테이블
            data = [
                ['분석 항목', '결과'],
                ['종합 감정', fusion_result.get('emotion_tag', 'N/A')],
                ['Valence (긍정성)', f"{fusion_result.get('final_vad', {}).get('valence', 0):.2f}"],
                ['Arousal (각성도)', f"{fusion_result.get('final_vad', {}).get('arousal', 0):.2f}"],
                ['Dominance (지배성)', f"{fusion_result.get('final_vad', {}).get('dominance', 0):.2f}"],
                ['사용된 모달리티', ', '.join(fusion_result.get('available_modalities', []))],
                ['분석 신뢰도', '높음' if len(fusion_result.get('available_modalities', [])) >= 2 else '보통']
            ]
            
            table = Table(data, colWidths=[2*inch, 3*inch])
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0, 0), (-1, -1), 1, colors.black)
            ]))
            story.append(table)
            story.append(Spacer(1, 20))
            
            # 해석
            interpretation = f"""
            현재 감정 상태는 '{fusion_result.get('emotion_tag', 'neutral')}'로 분석되었습니다.
            VAD 점수를 보면 긍정성은 {fusion_result.get('final_vad', {}).get('valence', 0):.2f}, 
            각성도는 {fusion_result.get('final_vad', {}).get('arousal', 0):.2f}, 
            지배성은 {fusion_result.get('final_vad', {}).get('dominance', 0):.2f}입니다.
            """
            interpretation_para = Paragraph(interpretation, self.custom_styles['body'])
            story.append(interpretation_para)
        
        return story
    
    def create_detailed_analysis_page(self, 
                                    face_result: Dict,
                                    audio_result: Dict,
                                    text_result: Dict,
                                    fusion_result: Dict) -> List:
        """상세 분석 페이지 생성"""
        story = []
        
        # 페이지 제목
        title = Paragraph("상세 분석 결과", self.custom_styles['subtitle'])
        story.append(title)
        story.append(Spacer(1, 20))
        
        # 얼굴 분석 결과
        if face_result.get('success'):
            story.append(Paragraph("1. 얼굴 표정 분석", self.custom_styles['section']))
            face_data = [
                ['분석 항목', '결과'],
                ['주요 감정', face_result.get('emotion', 'N/A')],
                ['신뢰도', f"{face_result.get('confidence', 0):.2f}"],
                ['Valence', f"{face_result.get('vad_score', {}).get('valence', 0):.2f}"],
                ['Arousal', f"{face_result.get('vad_score', {}).get('arousal', 0):.2f}"],
                ['Dominance', f"{face_result.get('vad_score', {}).get('dominance', 0):.2f}"]
            ]
            face_table = Table(face_data, colWidths=[1.5*inch, 2*inch])
            face_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.lightblue),
                ('GRID', (0, 0), (-1, -1), 1, colors.black)
            ]))
            story.append(face_table)
            story.append(Spacer(1, 15))
        
        # 음성 분석 결과
        if audio_result.get('success'):
            story.append(Paragraph("2. 음성 분석", self.custom_styles['section']))
            audio_data = [
                ['분석 항목', '결과'],
                ['음성 전사', audio_result.get('transcript', 'N/A')[:50] + '...' if len(audio_result.get('transcript', '')) > 50 else audio_result.get('transcript', 'N/A')],
                ['언어', audio_result.get('language', 'N/A')],
                ['Valence', f"{audio_result.get('vad_score', {}).get('valence', 0):.2f}"],
                ['Arousal', f"{audio_result.get('vad_score', {}).get('arousal', 0):.2f}"],
                ['Dominance', f"{audio_result.get('vad_score', {}).get('dominance', 0):.2f}"]
            ]
            audio_table = Table(audio_data, colWidths=[1.5*inch, 2*inch])
            audio_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.lightgreen),
                ('GRID', (0, 0), (-1, -1), 1, colors.black)
            ]))
            story.append(audio_table)
            story.append(Spacer(1, 15))
        
        # 텍스트 분석 결과
        if text_result.get('success'):
            story.append(Paragraph("3. 텍스트 감정 분석", self.custom_styles['section']))
            text_data = [
                ['분석 항목', '결과'],
                ['주요 감정', text_result.get('dominant_emotion', 'N/A')],
                ['감정 강도', f"{text_result.get('emotion_intensity', 0):.2f}"],
                ['분석된 단어 수', str(text_result.get('total_words', 0))],
                ['매칭된 단어 수', str(text_result.get('matched_count', 0))],
                ['Valence', f"{text_result.get('vad_score', {}).get('valence', 0):.2f}"],
                ['Arousal', f"{text_result.get('vad_score', {}).get('arousal', 0):.2f}"],
                ['Dominance', f"{text_result.get('vad_score', {}).get('dominance', 0):.2f}"]
            ]
            text_table = Table(text_data, colWidths=[1.5*inch, 2*inch])
            text_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.lightyellow),
                ('GRID', (0, 0), (-1, -1), 1, colors.black)
            ]))
            story.append(text_table)
        
        return story
    
    def create_cbt_strategy_page(self, cbt_strategy: Dict) -> List:
        """CBT 전략 페이지 생성"""
        story = []
        
        # 페이지 제목
        title = Paragraph("CBT 기반 감정 관리 전략", self.custom_styles['subtitle'])
        story.append(title)
        story.append(Spacer(1, 20))
        
        if cbt_strategy.get('success'):
            strategy = cbt_strategy.get('strategy', {})
            
            # 전략 개요
            story.append(Paragraph(f"추천 전략: {strategy.get('name', 'N/A')}", self.custom_styles['section']))
            description = Paragraph(strategy.get('description', ''), self.custom_styles['body'])
            story.append(description)
            story.append(Spacer(1, 15))
            
            # 주요 기법
            story.append(Paragraph("주요 기법:", self.custom_styles['section']))
            techniques = strategy.get('techniques', [])
            for i, technique in enumerate(techniques, 1):
                technique_para = Paragraph(f"{i}. {technique}", self.custom_styles['body'])
                story.append(technique_para)
            story.append(Spacer(1, 15))
            
            # 실습 활동
            story.append(Paragraph("실습 활동:", self.custom_styles['section']))
            exercises = strategy.get('exercises', [])
            for i, exercise in enumerate(exercises, 1):
                exercise_para = Paragraph(f"{i}. {exercise}", self.custom_styles['body'])
                story.append(exercise_para)
            story.append(Spacer(1, 15))
            
            # 개인화된 권장사항
            story.append(Paragraph("개인화된 권장사항:", self.custom_styles['section']))
            recommendations = cbt_strategy.get('personalized_recommendations', [])
            for i, recommendation in enumerate(recommendations, 1):
                rec_para = Paragraph(f"{i}. {recommendation}", self.custom_styles['highlight'])
                story.append(rec_para)
        
        return story
    
    def create_gpt_advice_page(self, gpt_response: Dict) -> List:
        """GPT 조언 페이지 생성"""
        story = []
        
        # 페이지 제목
        title = Paragraph("AI 전문가 조언", self.custom_styles['subtitle'])
        story.append(title)
        story.append(Spacer(1, 20))
        
        if gpt_response.get('success'):
            # GPT 응답
            response_text = gpt_response.get('response', '')
            response_para = Paragraph(response_text, self.custom_styles['body'])
            story.append(response_para)
            story.append(Spacer(1, 15))
            
            # 모델 정보
            model_info = f"생성 모델: {gpt_response.get('model', 'N/A')}"
            model_para = Paragraph(model_info, self.custom_styles['body'])
            story.append(model_para)
        
        return story
    
    def get_mock_result(self) -> Dict:
        """모킹 결과 반환 (테스트용)"""
        return {
            'success': True,
            'pdf_base64': 'mock_pdf_base64_string',
            'file_size': 1024,
            'filename': f'emotion_report_{datetime.now().strftime("%Y%m%d_%H%M%S")}.pdf'
        } 