        # 6. GPT 응답 생성
        logger.info("Starting GPT response generation...")
        gpt_result = gpt_service.generate_summary_response(
            face_result,
            audio_result,
            text_result,
            fusion_result,
            cbt_strategy_result
        )
        results['gpt_response'] = gpt_result.get('response', '') if gpt_result.get('success') else ''
        
        # 7. PDF 리포트 생성
        logger.info("Starting PDF report generation...")
        pdf_result = pdf_service.create_emotion_report(
            face_result,
            audio_result,
            text_result,
            fusion_result,
            cbt_strategy_result,
            gpt_result
        )
        results['pdf_report'] = pdf_result.get('pdf_base64', '') if pdf_result.get('success') else '' 