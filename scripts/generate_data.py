import os
import json
import random
import datetime
import pandas as pd
import numpy as np

def generate_edtech_dataset(output_dir=None, seed=42):
    if output_dir is None:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        output_dir = os.path.normpath(os.path.join(base_dir, "..", "data"))
        
    np.random.seed(seed)
    random.seed(seed)
    os.makedirs(output_dir, exist_ok=True)
    
    start_date = datetime.date(2026, 5, 1)
    end_date = datetime.date(2026, 10, 31)
    
    campaigns = {
        'c_google_search': {'channel': 'Search', 'cpc': 1.8, 'base_monthly_spend': [6000, 6500, 7000, 7200, 7500, 8000]},
        'c_fb_retargeting': {'channel': 'Social', 'cpc': 1.2, 'base_monthly_spend': [4000, 4200, 4500, 4800, 5000, 5200]},
        'c_blogs_affiliate': {'channel': 'Affiliate', 'cpc': 2.5, 'base_monthly_spend': [3000, 3200, 3500, 3600, 3800, 4000]},
        'c_youtube_tech': {'channel': 'Video', 'cpc': 1.5, 'base_monthly_spend': [5000, 5500, 6000, 6200, 6500, 7000]},
        'c_social_broad_scale': {'channel': 'Social Broad', 'cpc': 0.45, 'base_monthly_spend': [0, 0, 0, 0, 1500, 27500]}
    }
    
    spend_rows = []
    curr = start_date
    
    while curr <= end_date:
        m = curr.month - 5 # May is 0, Oct is 5
        for cmp_id, cmp_info in campaigns.items():
            monthly_budget = cmp_info['base_monthly_spend'][m]
            if monthly_budget > 0:
                days_in_month = 31 if curr.month in [5,7,8,10] else 30
                daily_spend = (monthly_budget / days_in_month) * np.random.uniform(0.9, 1.1)
                cpc = cmp_info['cpc'] * np.random.uniform(0.95, 1.05)
                clicks = int(daily_spend / cpc)
                impressions = clicks * np.random.randint(18, 32)
                
                spend_rows.append({
                    'spend_date': curr.strftime('%Y-%m-%d'),
                    'channel': cmp_info['channel'],
                    'campaign_id': cmp_id,
                    'spend_amount': round(daily_spend, 2),
                    'impressions': impressions,
                    'clicks': clicks
                })
        curr += datetime.timedelta(days=1)
        
    df_spend = pd.DataFrame(spend_rows)
    df_spend.to_csv(os.path.join(output_dir, 'marketing_spend.csv'), index=False)
    
    users = []
    sessions = []
    events = []
    subscriptions = []
    payments = []
    
    user_id_counter = 10001
    session_id_counter = 50001
    event_id_counter = 100001
    sub_id_counter = 70001
    pay_id_counter = 90001
    
    variant_noisy_map = {
        'variant_A': ['variant_A', 'variant_a', 'Variant_a'],
        'variant_B': ['variant_B', 'variant_b', 'Variant_b']
    }
    
    country_noisy_list = ['US', 'US', 'US', 'us', 'USA', 'UK', 'uk', 'CA', 'ca', 'DE', 'de', 'FR']
    channel_noisy_map = {
        'Search': ['Search', 'search'],
        'Social': ['Social', 'fb / social'],
        'Affiliate': ['Affiliate', 'affiliate'],
        'Video': ['Video', 'video'],
        'Social Broad': ['Social Broad', 'social broad']
    }
    
    for _, row in df_spend.iterrows():
        s_date = datetime.datetime.strptime(row['spend_date'], '%Y-%m-%d').date()
        cmp_id = row['campaign_id']
        channel = row['channel']
        clicks = row['clicks']
        
        if cmp_id == 'c_social_broad_scale':
            reg_rate = 0.048
        elif cmp_id == 'c_google_search':
            reg_rate = 0.22
        elif cmp_id == 'c_fb_retargeting':
            reg_rate = 0.18
        else:
            reg_rate = 0.15
            
        num_regs = int(clicks * reg_rate)
        
        for _ in range(num_regs):
            u_id = user_id_counter
            user_id_counter += 1
            
            secs = random.randint(0, 86399)
            reg_time = datetime.datetime.combine(s_date, datetime.time()) + datetime.timedelta(seconds=secs)
            
            if cmp_id == 'c_social_broad_scale':
                clean_variant = 'variant_B' if random.random() < 0.92 else 'variant_A'
            else:
                clean_variant = 'variant_A' if random.random() < 0.85 else 'variant_B'
                
            noisy_variant = random.choice(variant_noisy_map[clean_variant])
            
            # Missing data dirt
            device = np.random.choice(['desktop', 'mobile', 'tablet'], p=[0.55, 0.40, 0.05])
            device_user = None if random.random() < 0.025 else device
            
            raw_country = random.choice(country_noisy_list)
            country_user = None if random.random() < 0.045 else raw_country
            
            noisy_channel = random.choice(channel_noisy_map[channel])
            
            users.append({
                'user_id': u_id,
                'created_at': reg_time.strftime('%Y-%m-%d %H:%M:%S'),
                'acquisition_channel': noisy_channel,
                'campaign_id': cmp_id,
                'landing_variant': noisy_variant,
                'device': device_user,
                'country': country_user
            })
            
            # Web Session
            sess_id = session_id_counter
            session_id_counter += 1
            
            is_direct_organic = (random.random() < 0.058)
            utm_src = None if is_direct_organic else channel.lower().replace(' ', '_')
            utm_cmp = None if is_direct_organic else cmp_id
            
            sessions.append({
                'session_id': sess_id,
                'user_id': u_id,
                'session_start': reg_time.strftime('%Y-%m-%d %H:%M:%S'),
                'landing_page': f"/landing/{clean_variant}",
                'device': device_user,
                'utm_source': utm_src,
                'utm_campaign': utm_cmp
            })
            
            # Event 1: Landing visit
            events.append({
                'event_id': event_id_counter,
                'user_id': u_id,
                'session_id': sess_id if random.random() > 0.008 else None,
                'event_time': reg_time.strftime('%Y-%m-%d %H:%M:%S'),
                'event_name': 'landing_visit',
                'event_properties': json.dumps({'variant': clean_variant, 'device': device_user})
            })
            event_id_counter += 1
            
            # Event 2: Registration
            events.append({
                'event_id': event_id_counter,
                'user_id': u_id,
                'session_id': sess_id,
                'event_time': (reg_time + datetime.timedelta(seconds=45)).strftime('%Y-%m-%d %H:%M:%S'),
                'event_name': 'registration',
                'event_properties': json.dumps({'method': 'email'})
            })
            event_id_counter += 1
            
            # Event 3: Trial Start
            trial_time = reg_time + datetime.timedelta(seconds=90)
            events.append({
                'event_id': event_id_counter,
                'user_id': u_id,
                'session_id': sess_id,
                'event_time': trial_time.strftime('%Y-%m-%d %H:%M:%S'),
                'event_name': 'trial_start',
                'event_properties': json.dumps({'plan': '7_day_free_trial'})
            })
            event_id_counter += 1
            
            if random.random() < 0.005:
                events.append({
                    'event_id': event_id_counter,
                    'user_id': u_id,
                    'session_id': sess_id,
                    'event_time': trial_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'event_name': 'trial_start',
                    'event_properties': json.dumps({'plan': '7_day_free_trial'})
                })
                event_id_counter += 1
                
            # KEY PRODUCT ACTION
            if clean_variant == 'variant_B' and cmp_id == 'c_social_broad_scale':
                key_action_prob = 0.004
            elif clean_variant == 'variant_B':
                key_action_prob = 0.15
            else:
                key_action_prob = 0.68
                
            has_key_action = (random.random() < key_action_prob)
            
            if has_key_action:
                ka_time = trial_time + datetime.timedelta(minutes=random.randint(10, 1800))
                events.append({
                    'event_id': event_id_counter,
                    'user_id': u_id,
                    'session_id': sess_id,
                    'event_time': ka_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'event_name': 'key_product_action',
                    'event_properties': json.dumps({'action': 'completed_lesson_1', 'course': 'intro_python'})
                })
                event_id_counter += 1
                
            # Conversion to Paid
            if cmp_id == 'c_social_broad_scale':
                pay_prob = 0.01 if has_key_action else 0.00005
            else:
                pay_prob = 0.45 if has_key_action else 0.03
                
            converts_to_paid = (random.random() < pay_prob)
            
            sub_id = sub_id_counter
            sub_id_counter += 1
            
            trial_end_dt = trial_time + datetime.timedelta(days=7)
            
            if converts_to_paid:
                sub_status = 'active'
                subscriptions.append({
                    'subscription_id': sub_id,
                    'user_id': u_id,
                    'plan_type': 'monthly_49',
                    'status': sub_status,
                    'trial_start': trial_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'trial_end': trial_end_dt.strftime('%Y-%m-%d %H:%M:%S'),
                    'current_period_start': trial_end_dt.strftime('%Y-%m-%d %H:%M:%S'),
                    'current_period_end': (trial_end_dt + datetime.timedelta(days=30)).strftime('%Y-%m-%d %H:%M:%S')
                })
                
                payments.append({
                    'payment_id': pay_id_counter,
                    'user_id': u_id,
                    'subscription_id': sub_id,
                    'payment_time': trial_end_dt.strftime('%Y-%m-%d %H:%M:%S'),
                    'amount': 49.00,
                    'currency': 'USD',
                    'payment_status': 'succeeded',
                    'payment_method': np.random.choice(['credit_card', 'paypal', 'apple_pay'], p=[0.7, 0.2, 0.1])
                })
                pay_id_counter += 1
                
                next_pay_dt = trial_end_dt + datetime.timedelta(days=30)
                if next_pay_dt.date() <= end_date and random.random() < 0.75:
                    payments.append({
                        'payment_id': pay_id_counter,
                        'user_id': u_id,
                        'subscription_id': sub_id,
                        'payment_time': next_pay_dt.strftime('%Y-%m-%d %H:%M:%S'),
                        'amount': 49.00,
                        'currency': 'USD',
                        'payment_status': 'succeeded',
                        'payment_method': 'credit_card'
                    })
                    pay_id_counter += 1
            else:
                subscriptions.append({
                    'subscription_id': sub_id,
                    'user_id': u_id,
                    'plan_type': 'monthly_49',
                    'status': 'canceled',
                    'trial_start': trial_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'trial_end': trial_end_dt.strftime('%Y-%m-%d %H:%M:%S'),
                    'current_period_start': trial_end_dt.strftime('%Y-%m-%d %H:%M:%S'),
                    'current_period_end': trial_end_dt.strftime('%Y-%m-%d %H:%M:%S')
                })
                
                if random.random() < 0.01:
                    payments.append({
                        'payment_id': pay_id_counter,
                        'user_id': u_id,
                        'subscription_id': sub_id,
                        'payment_time': trial_time.strftime('%Y-%m-%d %H:%M:%S'),
                        'amount': 0.00,
                        'currency': 'USD',
                        'payment_status': 'failed',
                        'payment_method': None
                    })
                    pay_id_counter += 1

    pd.DataFrame(users).to_csv(os.path.join(output_dir, 'users.csv'), index=False)
    pd.DataFrame(sessions).to_csv(os.path.join(output_dir, 'web_sessions.csv'), index=False)
    pd.DataFrame(events).to_csv(os.path.join(output_dir, 'events.csv'), index=False)
    pd.DataFrame(subscriptions).to_csv(os.path.join(output_dir, 'subscriptions.csv'), index=False)
    pd.DataFrame(payments).to_csv(os.path.join(output_dir, 'payments.csv'), index=False)
    print("All CSVs generated successfully with realistic dirt in:", output_dir)

if __name__ == '__main__':
    generate_edtech_dataset()
