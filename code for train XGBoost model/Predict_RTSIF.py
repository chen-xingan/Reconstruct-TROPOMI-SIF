##### predict SIF for 2001-2019
####

import pandas as pd
import numpy as np
import os
import xgboost as xgb
import scipy.io as sio
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns
import joblib

model = joblib.load('./xgb_SIF.pkl')

for year in range(2002,2003):
    path = './input_csv/'+str(year)+'/'
    for info in os.listdir(path):
        domain = os.path.abspath(path)
        info1 = os.path.join(domain,info)
        print(info)
        data = pd.read_csv(info1)

        data['IGBP'] =  data['IGBP'].astype(str)

        category_feature_mask =  data.dtypes == object
        category_cols =  data.columns[category_feature_mask].tolist()
        data_categorical =  data[category_cols].copy()
        data_continuous =  data.drop(category_cols, axis = 1)

        data_continuous_data = std.transform( data_continuous)
        data_continuous_df = pd.DataFrame(data_continuous_data, columns = data_continuous.columns)

        data_categorical_data = enc.transform(data_categorical).toarray()
        data_categorical_df = pd.DataFrame(data_categorical_data, columns = [enc.get_feature_names()])

        data_new = pd.concat([data_continuous_df, data_categorical_df],axis=1)

        data_pred = model.predict(data_new)

        save_data = pd.DataFrame(data_pred, columns = ['Pred'])
        save_data.to_csv('./output_csv/'+str(year)+'/'+info,index=False,header=False)