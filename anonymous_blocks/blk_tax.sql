--DECLARE 
  v_dir                 VARCHAR2(30)  := 'DIR_XMLSDOCS'; 
  v_file                VARCHAR2(100) := 'AUDITORIA_CONCILIACAO_FISCAL_RF_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.xlsx';
  
  -- Parametrização centralizada das Fontes
  v_nome_fonte          VARCHAR2(30) := 'Arial'; 
  v_tamanho_fonte_dados NUMBER       := 8;   -- Tamanho para o corpo do texto
  v_tamanho_fonte_cabec NUMBER       := 10;  -- Tamanho para o header
  v_largura_padrao      NUMBER       := 18; 
  
  -- Identificadores de Fonte
  v_font_dados          PLS_INTEGER;
  v_font_cabec_branca   PLS_INTEGER;
  v_font_cabec_preta    PLS_INTEGER;
  
  -- Identificadores de Cor de Fundo (Novas Cores da View)
  v_fill_padrao         PLS_INTEGER;
  v_fill_verm_claro     PLS_INTEGER;
  v_fill_verde_esm      PLS_INTEGER;
  v_fill_amar_claro     PLS_INTEGER;
  v_fill_cinza_claro    PLS_INTEGER;
  
  -- Variáveis de controle do laço dinâmico
  v_fundo_atual         PLS_INTEGER;
  v_fonte_atual         PLS_INTEGER;
BEGIN
  as_xlsx.clear_workbook;
  
  as_xlsx.new_sheet('RF_UNIFICADA');
  
  -- 1. Criação das Instâncias de Fonte Separadas
  as_xlsx.set_font(v_nome_fonte, p_fontsize => v_tamanho_fonte_dados);
  
  -- Fonte do Corpo de Dados (Preta, Tamanho 8)
  v_font_dados        := as_xlsx.get_font(v_nome_fonte, p_fontsize => v_tamanho_fonte_dados, p_rgb => 'FF000000');
  
  -- Fontes do Cabeçalho (Negrito, Tamanho 10)
  v_font_cabec_branca := as_xlsx.get_font(v_nome_fonte, p_fontsize => v_tamanho_fonte_cabec, p_bold => true, p_rgb => 'FFFFFFFF');
  v_font_cabec_preta  := as_xlsx.get_font(v_nome_fonte, p_fontsize => v_tamanho_fonte_cabec, p_bold => true, p_rgb => 'FF000000');

  -- 2. Definição das Paletas de Cor de Fundo (Padrões ARGB HEX)
  v_fill_padrao       := as_xlsx.get_fill('solid', 'FF1F497D');  -- Azul escuro padrao
  v_fill_verm_claro   := as_xlsx.get_fill('solid', 'FFFF9999');  -- Vermelho Claro
  v_fill_verde_esm    := as_xlsx.get_fill('solid', 'FF50C878');  -- Verde Esmeralda
  v_fill_amar_claro   := as_xlsx.get_fill('solid', 'FFFFFF99');  -- Amarelo Claro
  v_fill_cinza_claro  := as_xlsx.get_fill('solid', 'FFD9D9D9');  -- Cinza Claro

  -- 3. Configuração ESTRUTURAL das colunas (Total de 143 da View + 1 customizada = 144)
  FOR i IN 1..144 LOOP
    as_xlsx.set_column_width(p_col => i, p_width => v_largura_padrao, p_sheet => 1);
    as_xlsx.set_column(p_col => i, p_fontId => v_font_dados, p_sheet => 1);
  END LOOP;

  as_xlsx.freeze_pane(p_col => 2, p_row => 2, p_sheet => 1);

  -- 4. Despeja os Dados Brutos da View
  as_xlsx.query2sheet(
    p_sql            => 'SELECT * FROM VW_UNIFICADA_RF',
    p_column_headers => true,
    p_sheet          => 1,
    p_UseXf          => true
  );

  -- 5. REESCRITA DINÂMICA DO CABEÇALHO (Linha 1) baseado na View
  FOR rec IN (
    SELECT column_name, column_id 
    FROM user_tab_columns 
    WHERE table_name = 'VW_UNIFICADA_RF' 
    ORDER BY column_id
  ) LOOP
    
    -- Mapeamento com as novas faixas e cores
    CASE 
      WHEN rec.column_id BETWEEN 1 AND 7 THEN
         v_fundo_atual := v_fill_verm_claro;
         v_fonte_atual := v_font_cabec_preta; -- Fonte preta para melhor contraste em fundo claro
      
      WHEN rec.column_id BETWEEN 8 AND 21 THEN
         v_fundo_atual := v_fill_verde_esm;
         v_fonte_atual := v_font_cabec_preta;
      
      WHEN rec.column_id BETWEEN 22 AND 37 THEN
         v_fundo_atual := v_fill_amar_claro;
         v_fonte_atual := v_font_cabec_preta;
      
      WHEN rec.column_id BETWEEN 38 AND 143 THEN
         v_fundo_atual := v_fill_cinza_claro;
         v_fonte_atual := v_font_cabec_preta;
      
      ELSE
         v_fundo_atual := v_fill_padrao;
         v_fonte_atual := v_font_cabec_branca;
    END CASE;

    -- Aplica as cores na primeira linha (Header)
    as_xlsx.cell(
      p_col    => rec.column_id, 
      p_row    => 1, 
      p_value  => rec.column_name, 
      p_fontId => v_fonte_atual, 
      p_fillId => v_fundo_atual, 
      p_sheet  => 1
    );
  END LOOP;

  -- 6. Adiciona a coluna customizada na última posição (144)
  as_xlsx.cell(
    p_col    => 144, 
    p_row    => 1, 
    p_value  => 'STATUS_AUDITORIA', 
    p_fontId => v_font_cabec_branca, 
    p_fillId => v_fill_padrao, 
    p_sheet  => 1
  );

  -- 7. Validação e Filtros
  as_xlsx.list_validation(
    p_sqref_col    => 144, 
    p_sqref_row    => 2, 
    p_defined_name => '"Validado,Pendente,Ajustar"', 
    p_style        => 'stop',
    p_title        => 'Status',
    p_prompt       => 'Selecione o status',
    p_show_error   => true,
    p_error_title  => 'Erro',
    p_error_txt    => 'Opcao invalida',
    p_sheet        => 1
  );

  -- Nota: O comentário está mantido na coluna 62, adapte caso o campo alvo do comentário tenha mudado na sua regra de negócio.
  as_xlsx.comment(
    p_col    => 62, 
    p_row    => 1, 
    p_text   => 'Base legal: Validar cruzamento com SPED Fiscal.', 
    p_author => 'Auditoria', 
    p_sheet  => 1
  );

  as_xlsx.set_autofilter(
    p_column_start => 1, 
    p_column_end   => 144, 
    p_row_start    => 1, 
    p_row_end      => 500000, 
    p_sheet        => 1
  );

  as_xlsx.save(v_dir, v_file);
  as_xlsx.clear_workbook;
  
  DBMS_OUTPUT.PUT_LINE('Arquivo ' || v_file || ' gerado com sucesso. Verifique a formatação.');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERRO: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('TRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    as_xlsx.clear_workbook;
    RAISE;
END;
/

Show errors;
