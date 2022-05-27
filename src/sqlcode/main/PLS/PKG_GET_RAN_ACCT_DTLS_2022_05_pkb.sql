CREATE OR REPLACE PACKAGE BODY PKG_GET_RAN_ACCT_DTLS_2022_05
AS
   /*########################################################################################
   NAME: CDF.PKG_GET_RAN_ACCT_DTLS_2022_05 -specification
   PURPOSE: PACKAGE created will will retrieve and return the RAN account details
   including real time balances, the RAN Account information and the Earning Mechanisms linked to the RAN along with CCR Bonus Details
   --CapAmount,AmountSpent and BonusAwardAmount.

   Revisions:

   Ver        Date                 Author                    Description
   ---------  ----------        ----------------          -------------------------------
   1.0        28/01/2022       Pavan Reddy Akiti              1. Created this package for CCR - Bonus Tracker project in 2.22
   **************************************************************************************/

   PROCEDURE sp_get_ran_acct_dtls_2022_05 (
      RAN_KEY_LIST               IN     RAN_KEY_TBL_2022_05,
      spv_disclosure_indicator   IN     VARCHAR2,
      RETURN_STATUS                 OUT VARCHAR2,
      ERR_CD                        OUT VARCHAR2,
      ERR_MSG                       OUT VARCHAR2,
      RAN_DETAILS_INFO              OUT RAN_DETAILS_CUR,
      EXP_SUMM_DETAILS_INFO         OUT EXP_SUMM_DETAILS_CUR,
      EM_BONUS_DETAILS_INFO         OUT EM_BONUS_DETAILS_CUR)
   IS
      /*Define Local variables.*/
      INVALID_INPUT                    EXCEPTION;
      NOT_FOUND                        EXCEPTION;
      ACCOUNT_DIRTY                    EXCEPTION;
      DISCLOSURE_NOT_FOUND             EXCEPTION;
      ran_key_lst_cnt                  NUMBER := 0;
      ran_key_actnum_lst_cnt           NUMBER := 0;
      ran_dtl_cnt                      NUMBER := 0;
      res_exp_sum_cnt                  NUMBER := 0;
      rew_em_dtl_cnt                   NUMBER := 0;
      bonus_dtl_cnt                    NUMBER := 0;
      bonus_dis_dtl_cnt                NUMBER := 0;
      dirty_cnt                        NUMBER := 0;
      get_ran_details_info             RAN_DETAILS_TBL_2022_05;
      get_exp_summ_details_info        EXP_SUMM_DETAILS_TBL_2022_05;
      get_em_bonus_details_info        EM_BONUS_DETAILS_TBL_2022_05;
      get_em_bonus_details_info_temp   EM_BONUS_DETAILS_TBL_2022_05;

      spv_data_chk_flg                 VARCHAR2 (100) := TRIM(RETURN_STATUS);
   BEGIN
      IF RAN_KEY_LIST.COUNT = 0
      THEN
         RAISE INVALID_INPUT;
      END IF;

      IF spv_disclosure_indicator IS NULL
      THEN
         RAISE INVALID_INPUT;
      END IF;

      IF spv_disclosure_indicator NOT IN ('true', 'false')
      THEN
         RAISE INVALID_INPUT;
      END IF;

      SELECT COUNT (1)
        INTO ran_key_lst_cnt
        FROM TABLE (CAST (RAN_KEY_LIST AS RAN_KEY_TBL_2022_05))
       WHERE    spv_acct_num IS NULL
             OR spv_comp_id IS NULL
             OR spv_acct_prdct_cd IS NULL;


      IF ran_key_lst_cnt > 0
      THEN
         RAISE INVALID_INPUT;
      END IF;

      SELECT data_check_indicator
        INTO spv_data_chk_flg
        FROM CHANNEL_MAPPING
       WHERE activity_source_id = 'CSTS';

      IF spv_data_chk_flg = 'Y'
      THEN
         RAISE ACCOUNT_DIRTY;
      END IF;

      SELECT COUNT (DISTINCT SPV_ACCT_NUM)
        INTO ran_key_actnum_lst_cnt
        FROM TABLE (CAST (RAN_KEY_LIST AS RAN_KEY_TBL_2022_05));

      SELECT COUNT (DISTINCT rdt.acct_num)
        INTO ran_dtl_cnt
        FROM RAN_DETAILS rdt,
             (SELECT LPAD (spv_acct_num, 23, 0) spv_acct_num,
                     spv_comp_id,
                     spv_acct_prdct_cd
                FROM TABLE (CAST (RAN_KEY_LIST AS RAN_KEY_TBL_2022_05)))
             RanKeytLst
       WHERE     rdt.acct_num = RanKeytLst.spv_acct_num
             AND rdt.acct_co_num = RanKeytLst.spv_comp_id
             AND rdt.ACCT_PRDCT_CD = RanKeytLst.spv_acct_prdct_cd;


      IF ran_key_actnum_lst_cnt <> ran_dtl_cnt
      THEN
         RAISE NOT_FOUND;
      END IF;


      /*RAN DETAILS CURSOR**/

      SELECT RAN_DETAILS_REC_2022_05 (
                rndtl.acct_num,
                rndtl.acct_prdct_cd,
                rndtl.acct_co_num,
                   TO_CHAR (rndtl.last_maint_dt_at_sor, 'YYYY-MM-DD')
                || 'T'
                || TO_CHAR (rndtl.last_maint_dt_at_sor, 'HH:MM:SS'),
                rndtl.current_bal,
                rndtl.expiring_bal,
                   TO_CHAR (rndtl.expiry_date, 'YYYY-MM-DD')
                || 'T'
                || '00:00:00',
                rndtl.currency_type,
                rndtl.auto_rdm_ind,
                rndtl.auto_rdm_acct_num,
                rndtl.auto_rdm_acct_prdct_cd,
                rndtl.auto_rdm_acct_co_num,
                rndtl.rdm_code,
                rndtl.acct_status,
                rndtl.rew_res_bal,
                rndtl.earn_more_mall_earnings,
                rndtl.adjustments,
                rndtl.ran_rdm_ratio_mult,
                rndtl.is_dirty)
        BULK COLLECT INTO get_ran_details_info
        FROM RAN_DETAILS rndtl,
             (SELECT LPAD (spv_acct_num, 23, 0) spv_acct_num,
                     spv_comp_id,
                     spv_acct_prdct_cd
                FROM TABLE (CAST (RAN_KEY_LIST AS RAN_KEY_TBL_2022_05)))
             RanKeytLst
       WHERE     rndtl.acct_num = RanKeytLst.spv_acct_num
             AND rndtl.acct_co_num = RanKeytLst.spv_comp_id
             AND rndtl.ACCT_PRDCT_CD = RanKeytLst.spv_acct_prdct_cd
             AND rndtl.MARK_FOR_DELETE = 'N';


      /*NOT FOUND Exception*/

      IF get_ran_details_info.COUNT = 0
      THEN
         RAISE NOT_FOUND;
      END IF;

      /*ACCOUNT DIRTY Exception*/
      SELECT COUNT (1)
        INTO dirty_cnt
        FROM (SELECT *
                FROM TABLE (
                        CAST (
                           get_ran_details_info AS RAN_DETAILS_TBL_2022_05)))
             tabl
       WHERE (tabl.is_dirty = 'Y');

      IF dirty_cnt > 0
      THEN
         RAISE ACCOUNT_DIRTY;
      END IF;

      /*EXP SUMMARY DETAILS CURSOR**/

      SELECT EXP_SUMM_DETAILS_REC_2022_05 (
                tbl1.RewardsAccountNumber,
                tbl1.ProductCode,
                tbl1.CompanyNumber,
                   TO_CHAR (rexsm.last_maint_dt_at_sor, 'YYYY-MM-DD')
                || 'T'
                || TO_CHAR (rexsm.last_maint_dt_at_sor, 'HH:MM:SS'),
                rexsm.amount,
                TO_CHAR (rexsm.exp_date, 'YYYY-MM-DD') || 'T' || '23:59:59')
        BULK COLLECT INTO get_exp_summ_details_info
        FROM REW_EXP_SUMM rexsm,
             (SELECT RewardsAccountNumber, ProductCode, CompanyNumber
                FROM TABLE (
                        CAST (
                           get_ran_details_info AS RAN_DETAILS_TBL_2022_05)))
             tbl1
       WHERE     rexsm.acct_num = tbl1.RewardsAccountNumber
             AND rexsm.acct_co_num = tbl1.CompanyNumber
             AND rexsm.ACCT_PRDCT_CD = tbl1.ProductCode
             AND rexsm.MARK_FOR_DELETE = 'N';

      IF get_exp_summ_details_info.COUNT = 0
      THEN
         OPEN EXP_SUMM_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   ExpirationLastUpdatedDateTime,
                   Amount,
                   Exp_Date
              FROM TABLE (
                      CAST (
                         get_exp_summ_details_info AS EXP_SUMM_DETAILS_TBL_2022_05))
             WHERE 1 = 2;
      END IF;

      /*EM and BONUS DETAILS CURSOR**/
      SELECT EM_BONUS_DETAILS_REC_2022_05 (
                tbl2.RewardsAccountNumber,
                tbl2.ProductCode,
                tbl2.CompanyNumber,
                remdtl.em_acct_num,
                remdtl.em_acct_prdct_cd,
                remdtl.em_acct_co_num,
                remdtl.em_prod_name,
                   TO_CHAR (remdtl.last_maint_dt_at_sor, 'YYYY-MM-DD')
                || 'T'
                || TO_CHAR (remdtl.last_maint_dt_at_sor, 'HH:MM:SS'),
                remdtl.em_status,
                   TO_CHAR (remdtl.ran_assc_start, 'YYYY-MM-DD')
                || 'T'
                || '00:00:00',
                remdtl.current_avail_bal,
                remdtl.pending_rew_bal,
                   TO_CHAR (remdtl.expct_rdm_date, 'YYYY-MM-DD')
                || 'T'
                || '00:00:00',
                remdtl.expiring_rew_bal,
                   TO_CHAR (remdtl.expiring_rew_date, 'YYYY-MM-DD')
                || 'T'
                || '00:00:00',
                remdtl.held_rew_bal,
                remdtl.life_time_erngs,
                remdtl.em_rdm_ratio_mplr,
                   TO_CHAR (bnsdtl.last_maint_dt_at_sor, 'YYYY-MM-DD')
                || 'T'
                || TO_CHAR (bnsdtl.last_maint_dt_at_sor, 'HH:MM:SS'),
                bnsdtl.bonus_code,
                bnsdtl.bonus_dscptn,
                   TO_CHAR (bnsdtl.bonus_start, 'YYYY-MM-DD')
                || 'T'
                || '00:00:00',
                TO_CHAR (bnsdtl.bonus_end, 'YYYY-MM-DD') || 'T' || '00:00:00',
                bnsdtl.thresh_acc,
                bnsdtl.bonus_rank,
                bnsdtl.threshold_amount,
                bnsdtl.remaining_spend,
                NULL,
                bnsdtl.disclosure_id,
                bnsdtl.CAP_AMOUNT,
                bnsdtl.AMOUNT_SPENT,
                bnsdtl.BONUS_AWARD_AMOUNT)
        BULK COLLECT INTO get_em_bonus_details_info_temp
        FROM REW_EM_DETAILS remdtl,
             BONUS_DETAILS bnsdtl,
             (SELECT RewardsAccountNumber, ProductCode, CompanyNumber
                FROM TABLE (
                        CAST (
                           get_ran_details_info AS RAN_DETAILS_TBL_2022_05)))
             tbl2
       WHERE     remdtl.acct_num = bnsdtl.acct_num
             AND remdtl.acct_co_num = bnsdtl.acct_co_num
             AND remdtl.ACCT_PRDCT_CD = bnsdtl.ACCT_PRDCT_CD
             AND remdtl.em_acct_num = bnsdtl.em_acct_num
             AND remdtl.em_acct_co_num = bnsdtl.em_acct_co_num
             AND remdtl.em_ACCT_PRDCT_CD = bnsdtl.em_ACCT_PRDCT_CD
             AND remdtl.acct_num = tbl2.RewardsAccountNumber
             AND remdtl.acct_co_num = tbl2.CompanyNumber
             AND remdtl.ACCT_PRDCT_CD = tbl2.ProductCode
             AND remdtl.MARK_FOR_DELETE = 'N'
             AND bnsdtl.MARK_FOR_DELETE = 'N';

      IF get_em_bonus_details_info_temp.COUNT = 0
      THEN
         OPEN EM_BONUS_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   EMAccountNumber,
                   EMProductCode,
                   EMCompanyNumber,
                   EMProductName,
                   EmLastUpdatedDateTime,
                   EMStatus,
                   RANAssociationStart,
                   CurrentAvailableBalance,
                   PendingRewardsBalance,
                   ExpectedRedeemableDate,
                   ExpiringRewardsBalance,
                   ExpiringRewardsDate,
                   HeldRewardsBalance,
                   LifetimeEarnings,
                   EmRedemptionRatioMultiplier,
                   BonusLastUpdatedDateTime,
                   BonusCode,
                   BonusDescription,
                   BonusStart,
                   BonusEnd,
                   ThresholdAccumulation,
                   BonusRANK,
                   ThresholdAmount,
                   RemainingSpend,
                   Disclosure,
                   CapAmount,
                   AmountSpent,
                   BonusAwardAmount
              FROM TABLE (
                      CAST (
                         get_em_bonus_details_info_temp AS EM_BONUS_DETAILS_TBL_2022_05))
             WHERE 1 = 2;
      END IF;

      IF lower(spv_disclosure_indicator) = 'false'
      THEN
         SELECT EM_BONUS_DETAILS_REC_2022_05 (
                   tbl.RewardsAccountNumber,
                   tbl.ProductCode,
                   tbl.CompanyNumber,
                   tbl.EMAccountNumber,
                   tbl.EMProductCode,
                   tbl.EMCompanyNumber,
                   tbl.EMProductName,
                   tbl.EmLastUpdatedDateTime,
                   tbl.EMStatus,
                   tbl.RANAssociationStart,
                   tbl.CurrentAvailableBalance,
                   tbl.PendingRewardsBalance,
                   tbl.ExpectedRedeemableDate,
                   tbl.ExpiringRewardsBalance,
                   tbl.ExpiringRewardsDate,
                   tbl.HeldRewardsBalance,
                   tbl.LifetimeEarnings,
                   tbl.EmRedemptionRatioMultiplier,
                   tbl.BonusLastUpdatedDateTime,
                   tbl.BonusCode,
                   tbl.BonusDescription,
                   tbl.BonusStart,
                   tbl.BonusEnd,
                   tbl.ThresholdAccumulation,
                   tbl.BonusRANK,
                   tbl.ThresholdAmount,
                   tbl.RemainingSpend,
                   tbl.Disclosure,
                   tbl.DisclosureId,
                   tbl.CapAmount,
                   tbl.AmountSpent,
                   tbl.BonusAwardAmount)
           BULK COLLECT INTO get_em_bonus_details_info
           FROM TABLE (
                   CAST (
                      get_em_bonus_details_info_temp AS EM_BONUS_DETAILS_TBL_2022_05))
                tbl;

         /* Open the EM BONUS DETAILS cursor to return resultset */
         OPEN EM_BONUS_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   EMAccountNumber,
                   EMProductCode,
                   EMCompanyNumber,
                   EMProductName,
                   EmLastUpdatedDateTime,
                   EMStatus,
                   RANAssociationStart,
                   CurrentAvailableBalance,
                   PendingRewardsBalance,
                   ExpectedRedeemableDate,
                   ExpiringRewardsBalance,
                   ExpiringRewardsDate,
                   HeldRewardsBalance,
                   LifetimeEarnings,
                   EmRedemptionRatioMultiplier,
                   BonusLastUpdatedDateTime,
                   BonusCode,
                   BonusDescription,
                   BonusStart,
                   BonusEnd,
                   ThresholdAccumulation,
                   BonusRANK,
                   ThresholdAmount,
                   RemainingSpend,
                   Disclosure,
                   CapAmount,
                   AmountSpent,
                   BonusAwardAmount                   
              FROM TABLE (
                      CAST (
                         get_em_bonus_details_info AS EM_BONUS_DETAILS_TBL_2022_05));
      ELSIF lower(spv_disclosure_indicator) = 'true'
      THEN
         SELECT COUNT (1)
           INTO bonus_dis_dtl_cnt
           FROM BONUS_DETAILS a,
                DISCLOSURE_DETAILS b,
                (SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber
                   FROM TABLE (CAST (get_ran_details_info AS RAN_DETAILS_TBL_2022_05)))
                tbl1
          WHERE     a.acct_num = tbl1.RewardsAccountNumber
                AND a.acct_co_num = tbl1.CompanyNumber
                AND a.ACCT_PRDCT_CD = tbl1.ProductCode
                AND a.DISCLOSURE_ID = b.DISCLOSURE_ID
                AND a.mark_for_delete='N';

         SELECT COUNT (1)
           INTO bonus_dtl_cnt
           FROM BONUS_DETAILS a,
            (SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber
                   FROM TABLE (CAST (get_ran_details_info AS RAN_DETAILS_TBL_2022_05)))
                tbl2
          WHERE      a.acct_num = tbl2.RewardsAccountNumber
                AND a.acct_co_num = tbl2.CompanyNumber
                AND a.ACCT_PRDCT_CD = tbl2.ProductCode
                AND a.mark_for_delete='N';

         IF bonus_dis_dtl_cnt != bonus_dtl_cnt
         THEN
            RAISE DISCLOSURE_NOT_FOUND;
         ELSE
            SELECT EM_BONUS_DETAILS_REC_2022_05 (
                      embndtl.RewardsAccountNumber,
                      embndtl.ProductCode,
                      embndtl.CompanyNumber,
                      embndtl.EMAccountNumber,
                      embndtl.EMProductCode,
                      embndtl.EMCompanyNumber,
                      embndtl.EMProductName,
                      embndtl.EmLastUpdatedDateTime,
                      embndtl.EMStatus,
                      embndtl.RANAssociationStart,
                      embndtl.CurrentAvailableBalance,
                      embndtl.PendingRewardsBalance,
                      embndtl.ExpectedRedeemableDate,
                      embndtl.ExpiringRewardsBalance,
                      embndtl.ExpiringRewardsDate,
                      embndtl.HeldRewardsBalance,
                      embndtl.LifetimeEarnings,
                      embndtl.EmRedemptionRatioMultiplier,
                      embndtl.BonusLastUpdatedDateTime,
                      embndtl.BonusCode,
                      embndtl.BonusDescription,
                      embndtl.BonusStart,
                      embndtl.BonusEnd,
                      embndtl.ThresholdAccumulation,
                      embndtl.BonusRANK,
                      embndtl.ThresholdAmount,
                      embndtl.RemainingSpend,
                      dsdtl.Disclosure_text,
                      embndtl.DisclosureId,
                      embndtl.CapAmount,
                      embndtl.AmountSpent,
                      embndtl.BonusAwardAmount)
              BULK COLLECT INTO get_em_bonus_details_info
              FROM TABLE (
                      CAST (
                         get_em_bonus_details_info_temp AS EM_BONUS_DETAILS_TBL_2022_05))
                   embndtl,
                   DISCLOSURE_DETAILS dsdtl
             WHERE embndtl.DisclosureId = dsdtl.Disclosure_Id;
         END IF;

         /* Open the EM BONUS DETAILS cursor to return resultset */
         OPEN EM_BONUS_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   EMAccountNumber,
                   EMProductCode,
                   EMCompanyNumber,
                   EMProductName,
                   EmLastUpdatedDateTime,
                   EMStatus,
                   RANAssociationStart,
                   CurrentAvailableBalance,
                   PendingRewardsBalance,
                   ExpectedRedeemableDate,
                   ExpiringRewardsBalance,
                   ExpiringRewardsDate,
                   HeldRewardsBalance,
                   LifetimeEarnings,
                   EmRedemptionRatioMultiplier,
                   BonusLastUpdatedDateTime,
                   BonusCode,
                   BonusDescription,
                   BonusStart,
                   BonusEnd,
                   ThresholdAccumulation,
                   BonusRANK,
                   ThresholdAmount,
                   RemainingSpend,
                   Disclosure,
                   CapAmount,
                   AmountSpent,
                   BonusAwardAmount                   
              FROM TABLE (
                      CAST (
                         get_em_bonus_details_info AS EM_BONUS_DETAILS_TBL_2022_05));
      END IF;


      /* Open the RAN DETAILS cursor to return resultset */
      OPEN RAN_DETAILS_INFO FOR
         SELECT RewardsAccountNumber,
                ProductCode,
                CompanyNumber,
                RanLastUpdatedDateTime,
                CurrentBalance,
                ExpiringBalance,
                ExpiringDate,
                CurrencyType,
                AutoRedemptionIndicator,
                AutoRdemtionAccountNumber,
                AutoRdemptionProductCode,
                AutoRedemptionCompanyNumber,
                RedemptionCode,
                Status,
                ReservedRewardsBalance,
                EarnMoreMallEarnings,
                Adjustments,
                RanRedemptionRatioMultiplier
           FROM TABLE (
                   CAST (get_ran_details_info AS RAN_DETAILS_TBL_2022_05));

      /* Open the EXP SUMM DETAILS cursor to return resultset */
      OPEN EXP_SUMM_DETAILS_INFO FOR
         SELECT RewardsAccountNumber,
                ProductCode,
                CompanyNumber,
                ExpirationLastUpdatedDateTime,
                Amount,
                Exp_Date
           FROM TABLE (
                   CAST (
                      get_exp_summ_details_info AS EXP_SUMM_DETAILS_TBL_2022_05));

      /* Open the EM and BONUS DETAILS cursor to return resultset */


      return_status := '0';
      err_cd := '00000';
   EXCEPTION
      WHEN NOT_FOUND
      THEN
         return_status := '-1';
         err_cd := '20001';
         err_msg := 'NOT_FOUND: NO ACCOUNT DETAILS FOUND FOR THE INPUT';

         /* Return an empty result set */
         OPEN RAN_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   RanLastUpdatedDateTime,
                   CurrentBalance,
                   ExpiringBalance,
                   ExpiringDate,
                   CurrencyType,
                   AutoRedemptionIndicator,
                   AutoRdemtionAccountNumber,
                   AutoRdemptionProductCode,
                   AutoRedemptionCompanyNumber,
                   RedemptionCode,
                   Status,
                   ReservedRewardsBalance,
                   EarnMoreMallEarnings,
                   Adjustments,
                   RanRedemptionRatioMultiplier
              FROM TABLE (
                      CAST (get_ran_details_info AS RAN_DETAILS_TBL_2022_05))
             WHERE 1 = 2;

         OPEN EXP_SUMM_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   ExpirationLastUpdatedDateTime,
                   Amount,
                   Exp_Date
              FROM TABLE (
                      CAST (
                         get_exp_summ_details_info AS EXP_SUMM_DETAILS_TBL_2022_05))
             WHERE 1 = 2;

         OPEN EM_BONUS_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   EMAccountNumber,
                   EMProductCode,
                   EMCompanyNumber,
                   EMProductName,
                   EmLastUpdatedDateTime,
                   EMStatus,
                   RANAssociationStart,
                   CurrentAvailableBalance,
                   PendingRewardsBalance,
                   ExpectedRedeemableDate,
                   ExpiringRewardsBalance,
                   ExpiringRewardsDate,
                   HeldRewardsBalance,
                   LifetimeEarnings,
                   EmRedemptionRatioMultiplier,
                   BonusLastUpdatedDateTime,
                   BonusCode,
                   BonusDescription,
                   BonusStart,
                   BonusEnd,
                   ThresholdAccumulation,
                   BonusRANK,
                   ThresholdAmount,
                   RemainingSpend,
                   Disclosure,
                   CapAmount,
                   AmountSpent,
                   BonusAwardAmount                   
              FROM TABLE (
                      CAST (
                         get_em_bonus_details_info AS EM_BONUS_DETAILS_TBL_2022_05))
             WHERE 1 = 2;
      WHEN INVALID_INPUT
      THEN
         return_status := '-1';
         err_cd := '20002';
         err_msg := 'INVALID_INPUT: INVALID PARAMETERS PASSED AS INPUT.';


         /* Return an empty result set */
         OPEN RAN_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   RanLastUpdatedDateTime,
                   CurrentBalance,
                   ExpiringBalance,
                   ExpiringDate,
                   CurrencyType,
                   AutoRedemptionIndicator,
                   AutoRdemtionAccountNumber,
                   AutoRdemptionProductCode,
                   AutoRedemptionCompanyNumber,
                   RedemptionCode,
                   Status,
                   ReservedRewardsBalance,
                   EarnMoreMallEarnings,
                   Adjustments,
                   RanRedemptionRatioMultiplier
              FROM TABLE (
                      CAST (get_ran_details_info AS RAN_DETAILS_TBL_2022_05))
             WHERE 1 = 2;

         OPEN EXP_SUMM_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   ExpirationLastUpdatedDateTime,
                   Amount,
                   Exp_Date
              FROM TABLE (
                      CAST (
                         get_exp_summ_details_info AS EXP_SUMM_DETAILS_TBL_2022_05))
             WHERE 1 = 2;

         OPEN EM_BONUS_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   EMAccountNumber,
                   EMProductCode,
                   EMCompanyNumber,
                   EMProductName,
                   EmLastUpdatedDateTime,
                   EMStatus,
                   RANAssociationStart,
                   CurrentAvailableBalance,
                   PendingRewardsBalance,
                   ExpectedRedeemableDate,
                   ExpiringRewardsBalance,
                   ExpiringRewardsDate,
                   HeldRewardsBalance,
                   LifetimeEarnings,
                   EmRedemptionRatioMultiplier,
                   BonusLastUpdatedDateTime,
                   BonusCode,
                   BonusDescription,
                   BonusStart,
                   BonusEnd,
                   ThresholdAccumulation,
                   BonusRANK,
                   ThresholdAmount,
                   RemainingSpend,
                   Disclosure,
                   CapAmount,
                   AmountSpent,
                   BonusAwardAmount                   
              FROM TABLE (
                      CAST (
                         get_em_bonus_details_info AS EM_BONUS_DETAILS_TBL_2022_05))
             WHERE 1 = 2;
      WHEN ACCOUNT_DIRTY
      THEN
         return_status := '-1';
         err_cd := '20003';
         err_msg := 'Account is dirty';


         /* Return an empty result set */
         OPEN RAN_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   RanLastUpdatedDateTime,
                   CurrentBalance,
                   ExpiringBalance,
                   ExpiringDate,
                   CurrencyType,
                   AutoRedemptionIndicator,
                   AutoRdemtionAccountNumber,
                   AutoRdemptionProductCode,
                   AutoRedemptionCompanyNumber,
                   RedemptionCode,
                   Status,
                   ReservedRewardsBalance,
                   EarnMoreMallEarnings,
                   Adjustments,
                   RanRedemptionRatioMultiplier
              FROM TABLE (
                      CAST (get_ran_details_info AS RAN_DETAILS_TBL_2022_05))
             WHERE 1 = 2;

         OPEN EXP_SUMM_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   ExpirationLastUpdatedDateTime,
                   Amount,
                   Exp_Date
              FROM TABLE (
                      CAST (
                         get_exp_summ_details_info AS EXP_SUMM_DETAILS_TBL_2022_05))
             WHERE 1 = 2;

         OPEN EM_BONUS_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   EMAccountNumber,
                   EMProductCode,
                   EMCompanyNumber,
                   EMProductName,
                   EmLastUpdatedDateTime,
                   EMStatus,
                   RANAssociationStart,
                   CurrentAvailableBalance,
                   PendingRewardsBalance,
                   ExpectedRedeemableDate,
                   ExpiringRewardsBalance,
                   ExpiringRewardsDate,
                   HeldRewardsBalance,
                   LifetimeEarnings,
                   EmRedemptionRatioMultiplier,
                   BonusLastUpdatedDateTime,
                   BonusCode,
                   BonusDescription,
                   BonusStart,
                   BonusEnd,
                   ThresholdAccumulation,
                   BonusRANK,
                   CapAmount,
                   AmountSpent,
                   BonusAwardAmount                   
              FROM TABLE (
                      CAST (
                         get_em_bonus_details_info AS EM_BONUS_DETAILS_TBL_2022_05))
             WHERE 1 = 2;
      WHEN DISCLOSURE_NOT_FOUND
      THEN
         return_status := '-1';
         err_cd := '20004';
         err_msg :=
            'NOT FOUND: NO DISCLOSURE DETAILS FOUND FOR THE DISCLOSURE ID';

         /* Return an empty result set */
         OPEN RAN_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   RanLastUpdatedDateTime,
                   CurrentBalance,
                   ExpiringBalance,
                   ExpiringDate,
                   CurrencyType,
                   AutoRedemptionIndicator,
                   AutoRdemtionAccountNumber,
                   AutoRdemptionProductCode,
                   AutoRedemptionCompanyNumber,
                   RedemptionCode,
                   Status,
                   ReservedRewardsBalance,
                   EarnMoreMallEarnings,
                   Adjustments,
                   RanRedemptionRatioMultiplier
              FROM TABLE (
                      CAST (get_ran_details_info AS RAN_DETAILS_TBL_2022_05))
             WHERE 1 = 2;

         OPEN EXP_SUMM_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   ExpirationLastUpdatedDateTime,
                   Amount,
                   Exp_Date
              FROM TABLE (
                      CAST (
                         get_exp_summ_details_info AS EXP_SUMM_DETAILS_TBL_2022_05))
             WHERE 1 = 2;

         OPEN EM_BONUS_DETAILS_INFO FOR
            SELECT RewardsAccountNumber,
                   ProductCode,
                   CompanyNumber,
                   EMAccountNumber,
                   EMProductCode,
                   EMCompanyNumber,
                   EMProductName,
                   EmLastUpdatedDateTime,
                   EMStatus,
                   RANAssociationStart,
                   CurrentAvailableBalance,
                   PendingRewardsBalance,
                   ExpectedRedeemableDate,
                   ExpiringRewardsBalance,
                   ExpiringRewardsDate,
                   HeldRewardsBalance,
                   LifetimeEarnings,
                   EmRedemptionRatioMultiplier,
                   BonusLastUpdatedDateTime,
                   BonusCode,
                   BonusDescription,
                   BonusStart,
                   BonusEnd,
                   ThresholdAccumulation,
                   BonusRANK,
                   ThresholdAmount,
                   RemainingSpend,
                   Disclosure,
                   CapAmount,
                   AmountSpent,
                   BonusAwardAmount                   
              FROM TABLE (
                      CAST (
                         get_em_bonus_details_info AS EM_BONUS_DETAILS_TBL_2022_05))
             WHERE 1 = 2;
      WHEN OTHERS
      THEN
         return_status := '-1';
         err_cd := SUBSTR (SQLERRM, 5, 5);
         err_msg := 'SYSTEM: ' || UPPER (SUBSTR (SQLERRM, 12));
   END sp_get_ran_acct_dtls_2022_05;
END PKG_GET_RAN_ACCT_DTLS_2022_05;
/
