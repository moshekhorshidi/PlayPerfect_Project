import streamlit as st
import pandas as pd
import plotly.express as px
from scipy import stats
import numpy as np

# ---------------------------------------------------------
# 1. Page Configuration and Data Loading
# ---------------------------------------------------------
st.set_page_config(layout="wide", page_title="Experiment Analysis")

@st.cache_data
def load_data():
    file_path = "streamlit_application\app_data_from_big_query.csv"
    try:
        df = pd.read_csv(file_path)
        if 'DATE' in df.columns:
            df['DATE'] = pd.to_datetime(df['DATE'])
        return df
    except FileNotFoundError:
        st.error(f"⚠️ File '{file_path}' not found. Please ensure it is in the same directory.")
        return pd.DataFrame()

df_raw = load_data()

if df_raw.empty:
    st.stop()

if 'room_tournaments' not in df_raw.columns:
    st.error("Error: Column 'room_tournaments' is missing from the CSV.")
    st.stop()

# ---------------------------------------------------------
# 2. Sidebar - Configuration
# ---------------------------------------------------------
st.sidebar.title("🔍 Configuration")

# --- A. Define Experiment Groups ---
st.sidebar.subheader("1. Define Groups")
all_tournaments = sorted(df_raw['room_tournaments'].dropna().unique())

control_tournaments = st.sidebar.multiselect(
    "Select Control Group (A):",
    options=all_tournaments,
    default=all_tournaments[:len(all_tournaments)//2]
)

available_for_test = [t for t in all_tournaments if t not in control_tournaments]
test_tournaments = st.sidebar.multiselect(
    "Select Test Group (B):",
    options=all_tournaments,
    default=available_for_test
)

# Apply Group Logic
df = df_raw.copy()

def assign_variant(tournament):
    if tournament in control_tournaments:
        return "Control Group"
    elif tournament in test_tournaments:
        return "Test Group"
    else:
        return "Unassigned"

df['Variant'] = df['room_tournaments'].apply(assign_variant)
df = df[df['Variant'] != "Unassigned"]

if df['Variant'].nunique() < 2:
    st.warning("⚠️ Please select tournaments for both groups.")
    st.stop()

# --- B. Analysis Settings ---
st.sidebar.subheader("2. Metrics")
analysis_type = st.sidebar.radio(
    "Select Domain:",
    ["Monetization", "Engagement", "Game Difficulty"]
)

metrics_map = {
    "Monetization": ["Room_Net_Profit", "Room_Gross_Revenue", "Total_Coins_Spent_In_Room"],
    "Engagement": ["Avg_Player_Duration", "Total_Coins_Spent_In_Room", "Player_Count"],
    "Game Difficulty": ["Avg_Score_In_Room", "Max_Score_In_Room"]
}

available_metrics = metrics_map[analysis_type]
valid_metrics = [m for m in available_metrics if m in df.columns]

if not valid_metrics:
    st.error("Required columns not found in CSV.")
    st.stop()

primary_metric = st.sidebar.selectbox("Select Primary Metric:", valid_metrics)

# --- C. Simulation Mode (NEW FEATURE) ---
st.sidebar.markdown("---")
st.sidebar.subheader("3. 🧪 Simulate Effect (Demo)")
enable_simulation = st.sidebar.checkbox("Enable Simulation Mode")

uplift_pct = 0.0
if enable_simulation:
    st.sidebar.info("This will artificially increase the Test Group values to demonstrate a successful experiment.")
    uplift_pct = st.sidebar.slider(
        f"Increase Test Group '{primary_metric}' by %:", 
        min_value=0, max_value=50, value=10, step=1
    )

# Apply Simulation Logic (Modify the dataframe in memory)
control_group = "Control Group"
test_group = "Test Group"

if enable_simulation and uplift_pct > 0:
    # We define a mask for the Test Group
    mask_test = df['Variant'] == test_group
    
    # We apply the uplift multiplier: Value * (1 + 10/100) = Value * 1.10
    # We use .loc to avoid warnings
    df.loc[mask_test, primary_metric] = df.loc[mask_test, primary_metric] * (1 + uplift_pct / 100)

# ---------------------------------------------------------
# 3. Main Dashboard
# ---------------------------------------------------------
st.title("🔬 Experiment Analysis Dashboard")
st.markdown(f"### 📊 Overview: {analysis_type}")

if enable_simulation:
    st.warning(f"🧪 **SIMULATION MODE ACTIVE:** Test Group '{primary_metric}' boosted by +{uplift_pct}%")

# KPI Row
cols = st.columns(len(valid_metrics))
for idx, metric in enumerate(valid_metrics):
    if idx < 3:
        avg_control = df[df['Variant'] == control_group][metric].mean()
        avg_test = df[df['Variant'] == test_group][metric].mean()
        
        if avg_control != 0 and not np.isnan(avg_control):
            delta_pct = ((avg_test - avg_control) / avg_control) * 100
        else:
            delta_pct = 0
            
        label_display = metric.replace("_", " ")
        cols[idx].metric(
            label=label_display, 
            value=f"{avg_test:,.2f}", 
            delta=f"{delta_pct:.1f}%",
            help=f"Control Avg: {avg_control:,.2f}"
        )

st.divider()

# ---------------------------------------------------------
# 4. Deep Dive & Stats
# ---------------------------------------------------------
col_viz, col_stats = st.columns([2, 1])

with col_viz:
    st.subheader(f"Deep Dive: {primary_metric}")
    tab1, tab2 = st.tabs(["📈 Daily Trend", "📊 Average Comparison"])
    
    with tab1:
        if 'DATE' in df.columns:
            daily_agg = df.groupby(['DATE', 'Variant'])[primary_metric].mean().reset_index()
            fig_line = px.line(
                daily_agg, x='DATE', y=primary_metric, color='Variant', markers=True,
                title=f"Daily Trend: {primary_metric}",
                color_discrete_map={control_group: '#636EFA', test_group: '#EF553B'}
            )
            st.plotly_chart(fig_line, use_container_width=True)
        else:
            st.info("No DATE column found.")

    with tab2:
        summary_df = df.groupby('Variant')[primary_metric].agg(['mean', 'sem']).reset_index()
        fig_bar = px.bar(
            summary_df, x='Variant', y='mean', error_y='sem', color='Variant', text_auto='.2f',
            title=f"Average {primary_metric} by Group",
            color_discrete_map={control_group: '#636EFA', test_group: '#EF553B'}
        )
        st.plotly_chart(fig_bar, use_container_width=True)

with col_stats:
    st.subheader("Statistical Test (T-Test)")
    
    group_1_data = df[df['Variant'] == control_group][primary_metric]
    group_2_data = df[df['Variant'] == test_group][primary_metric]
    
    if len(group_1_data) > 0 and len(group_2_data) > 0:
        t_stat, p_value = stats.ttest_ind(group_1_data, group_2_data)
        
        st.metric(label="P-Value", value=f"{p_value:.5f}")
        st.markdown("---")
        
        if p_value < 0.05:
            st.success("✅ **Significant!**")
            st.markdown(f"Confidence > 95%. The uplift of +{uplift_pct}% (if simulated) created a clear statistical difference.")
        else:
            st.warning("⚠️ **Not Significant**")
            st.markdown("Likely random noise. Try increasing the simulation uplift slider.")
    else:
        st.error("Not enough data in one of the groups to perform T-Test.")

# ---------------------------------------------------------
# 5. Raw Data Preview
# ---------------------------------------------------------
with st.expander("View Data (Includes Simulated Values if Active)"):
    st.dataframe(df.head(100))
